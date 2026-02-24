WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AveragePostScore,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        AVG(Reputation) AS AverageUserReputation
    FROM Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT PostId) AS UniqueVotedPosts
    FROM Votes
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        COUNT(DISTINCT PostId) AS UniqueCommentedPosts
    FROM Comments
)

SELECT 
    p.TotalPosts,
    p.AveragePostScore,
    p.UniquePostOwners,
    p.TotalQuestions,
    p.TotalAnswers,
    u.TotalUsers,
    u.TotalReputation,
    u.AverageUserReputation,
    v.TotalVotes,
    v.UniqueVotedPosts,
    c.TotalComments,
    c.UniqueCommentedPosts
FROM 
    PostStats p,
    UserStats u,
    VoteStats v,
    CommentStats c;