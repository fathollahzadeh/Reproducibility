WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgPostScore
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgPostScore,
    us.TotalUsers,
    us.AvgReputation
FROM PostStats ps, UserStats us
ORDER BY ps.TotalPosts DESC;