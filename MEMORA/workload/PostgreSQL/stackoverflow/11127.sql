WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPostStats AS (
    SELECT 
        ps.UserId,
        SUM(ps.TotalPosts) AS TotalPosts,
        SUM(ps.TotalQuestions) AS TotalQuestions,
        SUM(ps.TotalAnswers) AS TotalAnswers,
        SUM(ps.TotalViews) AS TotalViews,
        SUM(ps.TotalScore) AS TotalScore
    FROM 
        UserPostStats ps
    GROUP BY 
        ps.UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.TotalScore,
    RANK() OVER (ORDER BY ups.TotalScore DESC) AS ScoreRank
FROM 
    UserPostStats ups
ORDER BY 
    ups.TotalScore DESC
LIMIT 10;