WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), PostStats AS (
    SELECT P.OwnerUserId, P.PostTypeId, COUNT(*) AS PostCount, SUM(P.Score) AS TotalScore, SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId, P.PostTypeId
), DetailedStatistics AS (
    SELECT 
        U.DisplayName,
        UB.BadgeCount,
        PS.PostTypeId,
        PS.PostCount,
        PS.TotalScore,
        PS.TotalViews
    FROM UserBadges UB
    JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
    JOIN Users U ON U.Id = PS.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    SUM(CASE WHEN PostTypeId = 1 THEN PostCount ELSE 0 END) AS Questions,
    SUM(CASE WHEN PostTypeId = 2 THEN PostCount ELSE 0 END) AS Answers,
    SUM(TotalScore) AS AggregateScore,
    SUM(TotalViews) AS AggregateViews
FROM DetailedStatistics
GROUP BY DisplayName, BadgeCount
ORDER BY AggregateScore DESC, AggregateViews DESC;
