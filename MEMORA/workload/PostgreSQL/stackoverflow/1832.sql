
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePosts,
        COALESCE(SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    us.DisplayName AS Author,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    COALESCE(rc.CommentCount, 0) AS RecentComments,
    CASE 
        WHEN ps.Score > 10 THEN 'High Score'
        WHEN ps.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts ps
JOIN 
    UserStats us ON ps.OwnerUserId = us.UserId
LEFT JOIN 
    RecentComments rc ON ps.PostId = rc.PostId
WHERE 
    ps.PostRank = 1
ORDER BY 
    ps.CreationDate DESC
LIMIT 50;
