WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.AverageViews,
    us.TotalUsers,
    us.AverageReputation,
    us.TotalViews
FROM 
    PostStats ps,
    UserStats us
ORDER BY 
    ps.TotalPosts DESC;