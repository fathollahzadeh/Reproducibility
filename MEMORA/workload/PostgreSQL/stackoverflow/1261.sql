WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.LastAccessDate) AS LastAccess
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FrequentCommenters AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.UserId
    HAVING 
        COUNT(c.Id) > 10
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(ur.TotalReputation, 0) AS TotalUserReputation,
    COALESCE(uc.CommentCount, 0) AS FrequentCommentCount,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Popular'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity,
    CASE 
        WHEN rp.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 'Stale'
        ELSE 'Fresh'
    END AS Freshness
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    FrequentCommenters uc ON uc.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;