WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    MAX(rp.ViewCount) AS MostViewedPost,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    ub.BadgeCount > 0 AND rp.Rank <= 3
GROUP BY 
    up.DisplayName, ub.BadgeCount, ub.HighestBadgeClass
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 10;