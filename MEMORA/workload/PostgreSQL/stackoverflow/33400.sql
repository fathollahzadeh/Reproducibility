WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        0 AS Level
    FROM Users
    WHERE Reputation > 1000  
    
    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Id = ur.Id  
    WHERE u.Reputation < 1000  
),

RecentPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount, 
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),

PostTypeStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TypePostCount,
        SUM(p.Score) AS TotalScore
    FROM PostTypes pt
    LEFT JOIN Posts p ON p.PostTypeId = pt.Id
    GROUP BY pt.Id
)

SELECT 
    u.DisplayName,
    ur.Reputation,
    ur.CreationDate,
    rps.PostCount,
    rps.TotalScore,
    rps.AvgViews,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    pts.TypePostCount,
    pts.TotalScore AS TypeTotalScore
FROM Users u
JOIN UserReputationCTE ur ON u.Id = ur.Id
LEFT JOIN RecentPostStats rps ON u.Id = rps.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostTypeStats pts ON pts.TotalScore > 0
WHERE ur.Level = 0
ORDER BY ur.Reputation DESC
LIMIT 50;