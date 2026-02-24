WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM Comments
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation > 0 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM Users
)

SELECT 
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    c.TotalComments,
    u.TotalUsers,
    u.ActiveUsers
FROM PostCounts p, CommentCounts c, UserCounts u;