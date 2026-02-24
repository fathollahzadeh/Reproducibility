WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.AnswerCount,
        PS.TotalViews,
        PS.LatestPostDate,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS Rank
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 5
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.AnswerCount,
    TU.TotalViews,
    TU.LatestPostDate,
    PT.TagName,
    PT.PostCount,
    PT.TotalViews
FROM TopUsers TU
FULL OUTER JOIN PopularTags PT ON TU.Rank = PT.PostCount
WHERE TU.Reputation > 1000 OR PT.PostCount IS NOT NULL
ORDER BY TU.Reputation DESC, PT.TotalViews DESC;
