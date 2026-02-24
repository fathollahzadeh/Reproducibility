WITH UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.TotalBadges,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    tq.PostId,
    tq.Title,
    tq.Score,
    tq.CreationDate
FROM 
    UserReputation ur
LEFT JOIN 
    TopQuestions tq ON ur.UserId = tq.OwnerUserId
WHERE 
    tq.Rank <= 5
ORDER BY 
    ur.Reputation DESC, tq.Score DESC
LIMIT 100;
