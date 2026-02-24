WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS DistinctUsers,
        SUM(COALESCE(AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(CommentCount, 0)) AS TotalComments
    FROM 
        Posts
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation
    FROM 
        Users
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments 
    FROM 
        Comments
)
SELECT 
    (SELECT TotalPosts FROM PostCounts) AS TotalPosts,
    (SELECT DistinctUsers FROM PostCounts) AS DistinctUsers,
    (SELECT TotalAnswers FROM PostCounts) AS TotalAnswers,
    (SELECT TotalComments FROM PostCounts) AS TotalCommentsInPosts,
    (SELECT TotalUsers FROM UserCounts) AS TotalUsers,
    (SELECT TotalReputation FROM UserCounts) AS TotalReputation,
    (SELECT TotalComments FROM CommentCounts) AS TotalCommentsInComments