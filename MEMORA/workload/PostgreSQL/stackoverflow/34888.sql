WITH RECURSIVE UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        1 AS ActivityLevel
    FROM Users U
    WHERE U.Reputation > 1000
    
    UNION ALL

    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        UA.ActivityLevel + 1
    FROM Users U
    INNER JOIN UserActivity UA ON U.Id = UA.UserId
    WHERE UA.ActivityLevel < 3
),

PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),

PopularUsers AS (
    SELECT
        UA.UserId,
        UA.DisplayName,
        PSA.TotalPosts,
        PSA.Questions,
        PSA.Answers,
        PSA.AverageScore,
        PSA.TotalViews,
        ROW_NUMBER() OVER (ORDER BY PSA.TotalPosts DESC, PSA.AverageScore DESC) AS Ranking
    FROM UserActivity UA
    JOIN PostStatistics PSA ON UA.UserId = PSA.OwnerUserId
    WHERE UA.ActivityLevel >= 1
)

SELECT
    PU.DisplayName,
    PU.TotalPosts,
    PU.Questions,
    PU.Answers,
    PU.AverageScore,
    PU.TotalViews
FROM PopularUsers PU
LEFT JOIN Badges B ON PU.UserId = B.UserId
LEFT JOIN Votes V ON PU.UserId = V.UserId
WHERE (B.Class = 1 OR B.Class = 2) 
  AND (V.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' OR V.Id IS NULL) 
ORDER BY PU.Ranking
LIMIT 10;