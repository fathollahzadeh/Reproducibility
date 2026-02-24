WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.ViewCount
    HAVING 
        p.Score > 5 AND p.ViewCount > 100
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ub.DisplayName AS UserName,
    ub.BadgeCount,
    pp.Title AS PopularPost,
    pp.Score AS PostScore,
    pp.ViewCount,
    au.PostCount AS RecentPostCount
FROM 
    UserBadges ub
JOIN 
    PopularPosts pp ON ub.UserId = pp.OwnerUserId
JOIN 
    ActiveUsers au ON ub.UserId = au.UserId
ORDER BY 
    ub.BadgeCount DESC, pp.Score DESC, au.PostCount DESC
LIMIT 10;