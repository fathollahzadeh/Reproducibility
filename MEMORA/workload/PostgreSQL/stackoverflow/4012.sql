WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserWithMaxViews AS (
    SELECT 
        u.Id AS UserId,
        MAX(u.Views) AS MaxViews
    FROM 
        Users u
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    up.MaxViews,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    Users u
LEFT JOIN 
    UserWithMaxViews up ON u.Id = up.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RankByScore <= 5
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName, rp.Score DESC NULLS LAST;