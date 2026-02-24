WITH UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount, SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.ViewCount) AS TotalViews, 
           AVG(p.Score) AS AverageScore, COUNT(DISTINCT p.Tags) AS UniqueTagCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT u.Id AS UserId, u.DisplayName, ub.BadgeCount, ub.GoldCount, ub.SilverCount, ub.BronzeCount,
           ps.PostCount, ps.TotalViews, ps.AverageScore, ps.UniqueTagCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT UserId, DisplayName, BadgeCount, GoldCount, SilverCount, BronzeCount,
       PostCount, TotalViews, AverageScore, UniqueTagCount
FROM CombinedStats
WHERE BadgeCount > 0
ORDER BY TotalViews DESC, PostCount DESC
LIMIT 10;