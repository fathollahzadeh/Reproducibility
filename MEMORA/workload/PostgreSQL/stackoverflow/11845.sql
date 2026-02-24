WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN ParentId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
)

SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT TotalQuestions FROM PostStats) AS TotalQuestions,
    (SELECT TotalAnswers FROM PostStats) AS TotalAnswers,
    (SELECT TotalComments FROM PostStats) AS TotalComments,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AverageReputation FROM UserStats) AS AverageReputation,
    (SELECT TotalComments FROM CommentStats) AS TotalComments