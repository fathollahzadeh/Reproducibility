WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id
)
SELECT 
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.ViewCount,
    ua.PostCount,
    ua.TotalBounty,
    ps.CommentCount,
    ps.BadgeCount
FROM 
    RankedPosts ra
JOIN 
    UserActivity ua ON ra.PostId = ua.UserId
JOIN 
    PostStatistics ps ON ra.PostId = ps.PostId
WHERE 
    ra.Rank <= 5
ORDER BY 
    ra.Score DESC, 
    ra.ViewCount DESC;