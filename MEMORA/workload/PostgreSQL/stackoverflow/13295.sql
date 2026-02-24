WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
),
UserStatistics AS (
    SELECT 
        AVG(u.Reputation) AS AverageReputation,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)
SELECT 
    ps.PostTypeName,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalComments,
    us.AverageReputation,
    us.TotalBadges
FROM 
    PostStatistics ps,
    UserStatistics us
ORDER BY 
    ps.TotalPosts DESC;