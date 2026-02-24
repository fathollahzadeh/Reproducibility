WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS TotalDownvotedPosts,
        SUM(p.ViewCount) AS TotalViews
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
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalUpvotedPosts,
    u.TotalDownvotedPosts,
    u.TotalViews,
    AVG(COALESCE(p.Score, 0)) AS AvgScore,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    UserPostStats u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
GROUP BY 
    u.UserId, u.DisplayName, u.TotalPosts, u.TotalQuestions, u.TotalAnswers, u.TotalUpvotedPosts, u.TotalDownvotedPosts, u.TotalViews
ORDER BY 
    u.TotalPosts DESC;