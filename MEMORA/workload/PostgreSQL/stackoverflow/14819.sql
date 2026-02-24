
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewsByUser
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName, u.Reputation
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgScore,
    ps.TotalViews,
    ps.UniquePostOwners,
    ps.TotalComments,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.TotalViewsByUser
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.UniquePostOwners = us.TotalBadges
ORDER BY 
    ps.TotalPosts DESC, us.Reputation DESC;
