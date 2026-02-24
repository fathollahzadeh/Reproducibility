WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(p.Score) AS AveragePostScore,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(p.CommentCount) AS TotalCommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AveragePostScore,
    u.TotalViewCount,
    u.TotalCommentCount
FROM 
    UserPostStats u
ORDER BY 
    u.TotalPosts DESC
LIMIT 100;