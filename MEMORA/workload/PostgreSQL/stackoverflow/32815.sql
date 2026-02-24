
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostScoreCTE AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        RecentPosts rp
    WHERE 
        rp.rn = 1
),
AverageVotes AS (
    SELECT 
        AVG(CommentCount) AS AvgComments,
        AVG(UpvoteCount) AS AvgUpvotes,
        AVG(DownvoteCount) AS AvgDownvotes
    FROM 
        PostScoreCTE
),
PostAnalytics AS (
    SELECT 
        ps.Id,
        ps.Title,
        ps.OwnerDisplayName,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        CASE 
            WHEN ps.UpvoteCount > ps.DownvoteCount THEN 'Positive'
            WHEN ps.UpvoteCount < ps.DownvoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        CASE 
            WHEN ps.ViewCount > (SELECT AVG(ViewCount) FROM PostScoreCTE) THEN 1
            ELSE 0
        END AS IsAboveAverageViews
    FROM 
        PostScoreCTE ps
)
SELECT 
    pa.OwnerDisplayName,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.UpvoteCount,
    pa.DownvoteCount,
    pa.Sentiment,
    (SELECT AVG(AvgComments) FROM AverageVotes) AS OverallAvgComments,
    (SELECT AVG(AvgUpvotes) FROM AverageVotes) AS OverallAvgUpvotes,
    (SELECT AVG(AvgDownvotes) FROM AverageVotes) AS OverallAvgDownvotes
FROM 
    PostAnalytics pa
WHERE 
    pa.IsAboveAverageViews = 1
ORDER BY 
    pa.Score DESC;
