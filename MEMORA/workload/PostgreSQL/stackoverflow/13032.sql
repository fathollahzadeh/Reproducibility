
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(p.CommentCount), 0) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalViews,
        TotalAnswers,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    TotalAnswers,
    TotalComments,
    RankByScore,
    RankByViews
FROM 
    TopUsers
WHERE 
    RankByScore <= 10 OR RankByViews <= 10
ORDER BY 
    RankByScore, RankByViews;
