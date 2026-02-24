WITH UserBadgeStats AS (
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
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        UserBadgeStats
)
SELECT 
    u.Id,
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.Tags,
    t.BadgeRank,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    p.PostTypeId = 1 AND 
    t.BadgeRank <= 10 AND 
    p.Score > 10
ORDER BY 
    t.BadgeRank, p.Score DESC;
