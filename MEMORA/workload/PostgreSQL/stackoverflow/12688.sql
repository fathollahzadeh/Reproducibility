
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        p.OwnerUserId  -- Added OwnerUserId to GROUP BY clause
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId  -- Group by all selected columns
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeCount,
        AVG(u.Reputation) AS AverageReputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName  -- Group by all selected columns
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.VoteCount,
    pm.TotalBountyAmount,
    um.UserId,
    um.DisplayName,
    um.TotalBadgeCount,
    um.AverageReputation,
    um.PostCount
FROM 
    PostMetrics pm
JOIN 
    UserMetrics um ON pm.OwnerUserId = um.UserId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
