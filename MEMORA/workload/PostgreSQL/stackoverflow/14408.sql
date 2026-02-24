WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.ViewCount IS NOT NULL THEN 1 END) AS PostsWithViews,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsWithAcceptedAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPostsByUser,
        SUM(p.ViewCount) AS TotalViewsByUser,
        SUM(p.Score) AS TotalScoreByUser,
        AVG(p.Score) AS AverageScoreByUser
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PostsWithViews,
    ps.AverageScore,
    ps.AverageViews,
    ps.QuestionsWithAcceptedAnswers,
    us.DisplayName,
    us.TotalPostsByUser,
    us.TotalViewsByUser,
    us.TotalScoreByUser,
    us.AverageScoreByUser
FROM 
    PostStatistics ps
FULL OUTER JOIN 
    UserStatistics us ON TRUE
ORDER BY 
    ps.TotalPosts DESC, us.TotalPostsByUser DESC;