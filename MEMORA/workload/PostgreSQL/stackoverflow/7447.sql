WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(*) AS PostCount, SUM(P.Score) AS TotalScore, AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostUserStats AS (
    SELECT T.Id AS UserId, T.DisplayName, PS.PostCount, PS.TotalScore, PS.AvgViewCount, T.BadgeCount
    FROM TopUsers T
    LEFT JOIN PostStatistics PS ON T.Id = PS.OwnerUserId
)

SELECT P.Title, P.CreationDate, PS.DisplayName, PS.BadgeCount, PS.TotalScore, PS.AvgViewCount
FROM Posts P
JOIN PostUserStats PS ON P.OwnerUserId = PS.UserId
WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND P.Score > 0
ORDER BY PS.TotalScore DESC, P.CreationDate DESC
LIMIT 20;