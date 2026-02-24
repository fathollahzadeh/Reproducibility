
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    au.DisplayName,
    au.Reputation,
    COALESCE(rp.PostId, -1) AS LatestPostId,
    COALESCE(rp.Title, 'No Posts Yet') AS LatestPostTitle,
    COALESCE(rp.Score, 0) AS LatestPostScore,
    rp.Rank,
    rp.CommentCount,
    au.PostCount,
    au.TotalBadges
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId AND rp.Rank = 1
WHERE 
    au.PostCount > 0
ORDER BY 
    au.Reputation DESC,
    rp.Score DESC NULLS LAST
LIMIT 100;
