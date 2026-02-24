
WITH UserBadges AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(b.Id) AS BadgeCount, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(p.Id) AS PostCount,
           SUM(p.Score) AS TotalScore,
           AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT au.UserId,
           au.DisplayName, 
           ub.BadgeCount, 
           ub.GoldBadges, 
           ub.SilverBadges, 
           ub.BronzeBadges, 
           au.PostCount,
           au.TotalScore,
           au.AvgViewCount,
           RANK() OVER (ORDER BY au.TotalScore DESC, ub.BadgeCount DESC) AS UserRank
    FROM ActiveUsers au
    JOIN UserBadges ub ON au.UserId = ub.UserId
)
SELECT UserId, 
       DisplayName, 
       BadgeCount, 
       GoldBadges, 
       SilverBadges, 
       BronzeBadges, 
       PostCount, 
       TotalScore, 
       AvgViewCount, 
       UserRank
FROM TopUsers
WHERE UserRank <= 10 
ORDER BY UserRank;
