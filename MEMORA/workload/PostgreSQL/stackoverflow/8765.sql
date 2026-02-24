WITH UserBadges AS (
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
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.LastActivityDate - p.CreationDate) AS AvgPostDuration
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    ps.PostCount,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgPostDuration
FROM 
    TopUsers tu
LEFT JOIN 
    PostStatistics ps ON tu.Id = ps.OwnerUserId
WHERE 
    ps.PostCount > 5
ORDER BY 
    tu.Reputation DESC, ps.TotalScore DESC;
