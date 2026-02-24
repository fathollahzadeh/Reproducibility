
WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
HighReputationUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM UserReputation
    WHERE Rank <= 10
),
UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserPostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, 
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    ups.PostCount,
    ups.TotalViews,
    ups.AvgScore,
    'Total' AS Category
FROM HighReputationUsers u
JOIN UserBadges ub ON u.Id = ub.UserId
JOIN UserPostStats ups ON u.Id = ups.OwnerUserId
WHERE u.Reputation > 1000
UNION
SELECT 
    'All Users' AS DisplayName,
    SUM(u.Reputation) AS Reputation,
    SUM(ub.BadgeCount) AS BadgeCount,
    SUM(ups.PostCount) AS PostCount,
    SUM(ups.TotalViews) AS TotalViews,
    AVG(ups.AvgScore) AS AvgScore,
    'Summary' AS Category
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN UserPostStats ups ON u.Id = ups.OwnerUserId
WHERE u.Reputation IS NOT NULL
GROUP BY 'All Users', 'Summary'
HAVING COUNT(u.Id) > 0
ORDER BY Reputation DESC;
