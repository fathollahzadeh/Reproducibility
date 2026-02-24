WITH PostStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgPostScore,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Id, pt.Name
),
UserStats AS (
    SELECT 
        COUNT(DISTINCT u.Id) AS TotalUsers,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
)

SELECT 
    ps.PostTypeId,
    ps.PostTypeName,
    ps.TotalPosts,
    ps.AvgPostScore,
    us.TotalUsers,
    us.TotalReputation,
    ps.AvgUserReputation
FROM 
    PostStats ps, UserStats us
ORDER BY 
    ps.PostTypeId;