WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore,
        ps.TotalViews,
        ps.AvgViewsPerPost,
        ps.AvgScorePerPost
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(u.TotalPosts, 0) AS TotalPosts,
    COALESCE(u.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(u.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(u.TotalScore, 0) AS TotalScore,
    COALESCE(u.TotalViews, 0) AS TotalViews,
    COALESCE(u.AvgViewsPerPost, 0.0) AS AvgViewsPerPost,
    COALESCE(u.AvgScorePerPost, 0.0) AS AvgScorePerPost
FROM 
    UserStats u
ORDER BY 
    u.TotalPosts DESC
LIMIT 100;