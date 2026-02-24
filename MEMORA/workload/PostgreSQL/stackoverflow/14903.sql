WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        SUM(COALESCE(AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(CommentCount, 0)) AS TotalComments
    FROM Posts
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters
    FROM Votes
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        MAX(Reputation) AS MaxReputation
    FROM Users
)

SELECT 
    p.TotalPosts,
    p.UniqueUsers,
    p.TotalAnswers,
    p.TotalComments,
    v.TotalVotes,
    v.UniqueVoters,
    u.TotalUsers,
    u.AvgReputation,
    u.MaxReputation
FROM 
    PostStats p,
    VoteStats v,
    UserStats u;