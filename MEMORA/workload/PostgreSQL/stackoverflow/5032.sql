WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS PostCount, SUM(P.Score) AS TotalScore, AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    WHERE P.CreationDate >= '2023-01-01'
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UB.BadgeCount, PS.PostCount, PS.TotalScore, PS.AvgViewCount
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT U.DisplayName, U.Reputation, U.BadgeCount, U.PostCount, U.TotalScore, U.AvgViewCount
FROM UserActivity U
WHERE U.Reputation > 1000
ORDER BY U.TotalScore DESC, U.BadgeCount DESC
LIMIT 10;
