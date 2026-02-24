WITH UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
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
        TotalQuestions,
        TotalAnswers,
        PositivePosts,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserPostStatistics
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    PositivePosts,
    TotalViews,
    AverageScore,
    RankByPosts,
    RankByViews
FROM 
    TopUsers
WHERE 
    RankByPosts <= 10 OR RankByViews <= 10
ORDER BY 
    RankByPosts, RankByViews;