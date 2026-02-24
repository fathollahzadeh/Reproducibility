
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        MAX(p.LastActivityDate) AS MostRecentActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        Id AS PostId,
        Title,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerUserId
    FROM 
        Posts
    WHERE 
        CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.AverageScore,
    us.MostRecentActivity,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.TotalPosts DESC, us.AverageScore DESC;
