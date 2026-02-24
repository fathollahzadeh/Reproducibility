WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
PostTypesStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM PostTypes PT
    LEFT JOIN Posts P ON PT.Id = P.PostTypeId
    GROUP BY PT.Id, PT.Name
)
SELECT 
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.PostCount,
    US.TotalScore,
    US.TotalViews,
    US.LastPostDate,
    PTS.PostTypeId,
    PTS.PostTypeName,
    PTS.PostCount AS PostsPerType,
    PTS.TotalScore AS ScorePerType,
    PTS.TotalViews AS ViewsPerType
FROM UserStats US
JOIN PostTypesStats PTS ON US.PostCount > 0
ORDER BY US.Reputation DESC, PTS.PostCount DESC;