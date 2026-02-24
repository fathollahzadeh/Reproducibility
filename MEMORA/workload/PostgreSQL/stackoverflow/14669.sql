WITH UserPostStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(p.Id) as TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) as TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) as TotalAnswers,
        SUM(p.Score) as TotalScore,
        SUM(p.ViewCount) as TotalViews,
        AVG(p.LastActivityDate - p.CreationDate) as AvgPostAge
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
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        AvgPostAge
    FROM 
        UserPostStats
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)

SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalScore,
    t.TotalViews,
    t.AvgPostAge
FROM 
    TopUsers t;