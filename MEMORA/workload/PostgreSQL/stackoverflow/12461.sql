WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        MAX(Reputation) AS MaxReputation,
        MIN(Reputation) AS MinReputation
    FROM 
        Users
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgViewCount,
    ps.TotalScore,
    us.TotalUsers,
    us.AvgReputation,
    us.MaxReputation,
    us.MinReputation
FROM 
    PostStats ps, UserStats us
ORDER BY 
    ps.TotalPosts DESC;