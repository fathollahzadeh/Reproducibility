
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS UserOwnedCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Reputation
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.AverageViewCount,
    ps.UserOwnedCount,
    COUNT(us.Reputation) AS UserCount,
    AVG(us.Reputation) AS AverageReputation,
    SUM(us.TotalBadges) AS TotalBadges,
    SUM(us.TotalComments) AS TotalComments
FROM 
    PostStats ps
JOIN 
    UserStats us ON 1 = 1  
GROUP BY 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.AverageViewCount,
    ps.UserOwnedCount
ORDER BY 
    ps.TotalPosts DESC;
