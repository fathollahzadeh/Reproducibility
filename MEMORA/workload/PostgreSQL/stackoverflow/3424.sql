
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes,
        rn
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
FilteredPosts AS (
    SELECT 
        tp.*,
        CASE 
            WHEN tp.Score > 100 THEN 'High Score'
            WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        COALESCE(u.DisplayName, 'Community') AS OwnerName
    FROM 
        TopPosts tp
        LEFT JOIN Users u ON tp.PostId = u.Id
)
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AverageViews,
    SUM(CASE WHEN ScoreCategory = 'High Score' THEN 1 ELSE 0 END) AS HighScorePosts,
    SUM(CASE WHEN ScoreCategory = 'Medium Score' THEN 1 ELSE 0 END) AS MediumScorePosts,
    SUM(CASE WHEN ScoreCategory = 'Low Score' THEN 1 ELSE 0 END) AS LowScorePosts
FROM 
    FilteredPosts
WHERE 
    CreationDate <= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days'
UNION ALL
SELECT 
    COUNT(DISTINCT UserId) AS UniqueActiveUsers,
    NULL AS AverageViews,
    NULL AS HighScorePosts,
    NULL AS MediumScorePosts,
    NULL AS LowScorePosts
FROM 
    Votes 
WHERE 
    CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days';
