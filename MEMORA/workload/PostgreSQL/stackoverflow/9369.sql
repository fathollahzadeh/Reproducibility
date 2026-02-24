WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserStats
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalScore,
    TU.TotalViews,
    CASE 
        WHEN TU.ScoreRank <= 10 THEN 'Top Contributor'
        WHEN TU.ScoreRank BETWEEN 11 AND 50 THEN 'Contributing Member'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM TopUsers TU
WHERE TU.TotalPosts > 0
ORDER BY TU.TotalScore DESC
LIMIT 20;
