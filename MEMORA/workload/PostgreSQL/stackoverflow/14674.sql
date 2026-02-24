WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AverageAnswersPerQuestion
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalAnswers,
    u.TotalQuestions,
    u.AverageScore,
    u.TotalViews,
    u.AverageAnswersPerQuestion
FROM 
    UserPostStats u
ORDER BY 
    u.TotalPosts DESC
LIMIT 10;