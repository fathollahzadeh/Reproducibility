
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PopularPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.OwnerUserId, p.Id, p.Score, p.ViewCount, p.Title
    HAVING 
        COUNT(c.Id) >= 5 
), 
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pp.PostId,
        pp.Score,
        pp.ViewCount,
        pp.Title
    FROM 
        Users u
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    JOIN 
        PopularPosts pp ON u.Id = pp.OwnerUserId
    ORDER BY 
        u.Reputation DESC,
        ub.BadgeCount DESC
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.CreationDate,
    au.BadgeCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    au.Title,
    au.Score AS PostScore,
    au.ViewCount AS PostViewCount
FROM 
    ActiveUsers au
WHERE 
    au.BadgeCount > 0 AND
    au.Reputation > 100 
ORDER BY 
    au.Reputation DESC,
    au.BadgeCount DESC;
