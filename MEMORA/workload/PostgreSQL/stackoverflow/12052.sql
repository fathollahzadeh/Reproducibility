WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViews
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalScore,
        TotalViews,
        AvgScore,
        AvgViews,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM
        UserStats
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalScore,
    TotalViews,
    AvgScore,
    AvgViews,
    ScoreRank,
    ViewRank
FROM
    TopUsers
WHERE
    ScoreRank <= 10 OR ViewRank <= 10
ORDER BY
    ScoreRank, ViewRank;