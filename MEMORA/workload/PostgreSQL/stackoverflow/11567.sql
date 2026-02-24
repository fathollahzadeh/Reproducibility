WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        MAX(CreationDate) AS MostRecentUserCreation
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters,
        COUNT(DISTINCT PostId) AS UniqueVotedPosts
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.UniquePostOwners,
    p.TotalQuestions,
    p.TotalAnswers,
    p.TotalTagWikis,
    u.TotalUsers,
    u.AvgReputation,
    u.MostRecentUserCreation,
    v.TotalVotes,
    v.UniqueVoters,
    v.UniqueVotedPosts
FROM 
    PostStats p,
    UserStats u,
    VoteStats v;