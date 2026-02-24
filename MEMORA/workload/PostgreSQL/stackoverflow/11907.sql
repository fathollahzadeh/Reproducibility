WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        AVG(p.AnswerCount) AS AverageAnswerCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalPostsByUser,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    ps.AverageAnswerCount,
    ps.UniquePostOwners,
    us.DisplayName,
    us.TotalBadges,
    us.TotalPostsByUser,
    us.TotalBountyAmount
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.UniquePostOwners > 0
ORDER BY 
    ps.TotalPosts DESC, us.TotalBadges DESC;