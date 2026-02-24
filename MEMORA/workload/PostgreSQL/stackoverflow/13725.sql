WITH PostsStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UsersStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalViews,
        us.TotalScore,
        us.AvgScore,
        us.AvgViews
    FROM 
        Users u
    LEFT JOIN 
        PostsStats us ON u.Id = us.OwnerUserId
)

SELECT 
    u.UserId,
    u.Reputation,
    COALESCE(u.TotalPosts, 0) AS TotalPosts,
    COALESCE(u.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(u.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(u.TotalViews, 0) AS TotalViews,
    COALESCE(u.TotalScore, 0) AS TotalScore,
    COALESCE(u.AvgScore, 0) AS AvgScore,
    COALESCE(u.AvgViews, 0) AS AvgViews
FROM 
    UsersStats u
ORDER BY 
    u.TotalPosts DESC;