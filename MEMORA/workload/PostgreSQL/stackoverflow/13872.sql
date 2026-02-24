WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AverageQuestionScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPostsByUser,
        SUM(COALESCE(b.Id, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    ps.PostTypeName,
    ps.TotalPosts,
    ps.AverageQuestionScore,
    ps.TotalComments,
    us.Reputation,
    us.TotalPostsByUser,
    us.TotalBadges
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.TotalPostsByUser > 0
ORDER BY 
    ps.TotalPosts DESC;