WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), ActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ap.PostCount, 0) AS ActivePostCount,
    COALESCE(ap.TotalScore, 0) AS ActivePostScore
FROM 
    RankedUsers ru
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
LEFT JOIN 
    ActivePosts ap ON ru.UserId = ap.OwnerUserId
ORDER BY 
    ru.ReputationRank, ru.Reputation DESC;