WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgViews,
    ps.AvgScore,
    ps.UniqueUsers,
    us.TotalUsers,
    us.AvgReputation
FROM 
    PostStats ps,
    UserStats us
ORDER BY 
    ps.TotalPosts DESC;