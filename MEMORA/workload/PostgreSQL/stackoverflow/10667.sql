WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(v.BountyAmount) AS TotalBountyReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.UniqueUsers,
    ps.TotalViews,
    ps.TotalComments,
    ps.TotalAnswers,
    us.UserId,
    us.DisplayName,
    us.PostsCreated,
    us.TotalBountyReceived
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.UniqueUsers = us.PostsCreated
ORDER BY 
    TotalPosts DESC;