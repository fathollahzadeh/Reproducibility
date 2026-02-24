WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
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
        UserName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    UserName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    RankByScore,
    RankByViews
FROM 
    TopUsers
WHERE 
    RankByScore <= 10 OR RankByViews <= 10
ORDER BY 
    RankByScore, RankByViews;