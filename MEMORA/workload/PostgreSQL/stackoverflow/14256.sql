WITH PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        SUM(CASE WHEN OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsWithUsers,
        AVG(ViewCount) AS AverageViews,
        AVG(Score) AS AverageScore,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
),
UserStatistics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        MAX(Reputation) AS MaxReputation,
        MIN(Reputation) AS MinReputation
    FROM 
        Users
),
VoteStatistics AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters,
        AVG(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpvotes,
        AVG(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownvotes
    FROM 
        Votes
)

SELECT 
    ps.TotalPosts,
    ps.UniquePostOwners,
    ps.PostsWithUsers,
    ps.AverageViews,
    ps.AverageScore,
    ps.TotalQuestions,
    ps.TotalAnswers,
    us.TotalUsers,
    us.AverageReputation,
    us.MaxReputation,
    us.MinReputation,
    vs.TotalVotes,
    vs.UniqueVoters,
    vs.AverageUpvotes,
    vs.AverageDownvotes
FROM 
    PostStatistics ps,
    UserStatistics us,
    VoteStatistics vs;