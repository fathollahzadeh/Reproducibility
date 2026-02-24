WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
    LIMIT 10
),
PostStats AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS PostCount, SUM(P.ViewCount) AS TotalViews, AVG(P.Score) AS AvgScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT TU.Id AS UserId, TU.DisplayName, TU.Reputation, TU.CreationDate, TU.LastAccessDate, TU.BadgeCount,
           COALESCE(PS.PostCount, 0) AS PostCount, COALESCE(PS.TotalViews, 0) AS TotalViews, COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM TopUsers TU
    LEFT JOIN PostStats PS ON TU.Id = PS.OwnerUserId
)
SELECT CS.UserId, CS.DisplayName, CS.Reputation, CS.CreationDate, CS.LastAccessDate, CS.BadgeCount,
       CS.PostCount, CS.TotalViews, CS.AvgScore, RANK() OVER (ORDER BY CS.TotalViews DESC) AS ViewsRank,
       RANK() OVER (ORDER BY CS.AvgScore DESC) AS ScoreRank
FROM CombinedStats CS
ORDER BY CS.Reputation DESC, CS.BadgeCount DESC;