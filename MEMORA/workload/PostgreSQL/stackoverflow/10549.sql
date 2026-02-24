WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis
    FROM 
        Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation >= 1000 THEN 1 ELSE 0 END) AS InfluentialUsers
    FROM 
        Users
)
SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT TotalQuestions FROM PostStats) AS TotalQuestions,
    (SELECT TotalAnswers FROM PostStats) AS TotalAnswers,
    (SELECT TotalTagWikis FROM PostStats) AS TotalTagWikis,
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT InfluentialUsers FROM UserStats) AS InfluentialUsers;