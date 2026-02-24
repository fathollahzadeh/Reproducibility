WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis
    FROM 
        Posts
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation > 1000 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM 
        Users
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes
)

SELECT 
    (SELECT TotalPosts FROM PostCounts) AS TotalPosts,
    (SELECT TotalQuestions FROM PostCounts) AS TotalQuestions,
    (SELECT TotalAnswers FROM PostCounts) AS TotalAnswers,
    (SELECT TotalTagWikis FROM PostCounts) AS TotalTagWikis,
    (SELECT TotalUsers FROM UserCounts) AS TotalUsers,
    (SELECT ActiveUsers FROM UserCounts) AS ActiveUsers,
    (SELECT TotalComments FROM CommentCounts) AS TotalComments,
    (SELECT TotalVotes FROM VoteCounts) AS TotalVotes,
    (SELECT TotalUpvotes FROM VoteCounts) AS TotalUpvotes,
    (SELECT TotalDownvotes FROM VoteCounts) AS TotalDownvotes;