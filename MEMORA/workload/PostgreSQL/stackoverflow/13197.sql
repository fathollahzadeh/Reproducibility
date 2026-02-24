WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalQuestions,
    ps.TotalAnswers,
    us.TotalUsers,
    us.AverageReputation
FROM 
    PostStats ps,
    UserStats us
ORDER BY 
    ps.TotalPosts DESC;