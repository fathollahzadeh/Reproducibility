WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ubc.BadgeCount,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges,
        pp.Title AS MostViewedPostTitle,
        pp.ViewCount AS MostViewedPostCount
    FROM 
        Users u
    JOIN 
        UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN 
        PopularPosts pp ON u.Id = pp.OwnerUserId AND pp.rn = 1
    WHERE 
        u.Reputation > 1000  
)
SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tu.Reputation, 
    tu.BadgeCount, 
    tu.GoldBadges, 
    tu.SilverBadges, 
    tu.BronzeBadges, 
    tu.MostViewedPostTitle, 
    tu.MostViewedPostCount
FROM 
    TopUsers tu
ORDER BY 
    tu.Reputation DESC, 
    tu.BadgeCount DESC
LIMIT 10;