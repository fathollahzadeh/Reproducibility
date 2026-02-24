
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostStatistics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.OwnerName,
        r.Upvotes,
        r.Downvotes,
        r.CommentCount,
        ROW_NUMBER() OVER (ORDER BY r.Upvotes - r.Downvotes DESC) AS Rank,
        CASE 
            WHEN r.Upvotes > r.Downvotes THEN 'Positive'
            WHEN r.Upvotes < r.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RecentPosts r
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerName,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    ps.Rank,
    ps.Sentiment,
    NULLIF(ps.Upvotes - ps.Downvotes, 0) AS VoteDifference,
    CASE 
        WHEN ps.CommentCount > 10 THEN 'High Engagement'
        WHEN ps.CommentCount BETWEEN 5 AND 10 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 10
ORDER BY 
    ps.Rank;
