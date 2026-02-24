WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        AVG(Views) AS AvgViews
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT PostId) AS UniqueVotedPosts,
        COUNT(DISTINCT UserId) AS UniqueVoters
    FROM 
        Votes
)

SELECT 
    ps.TotalPosts,
    ps.UniquePostOwners,
    ps.AvgViewCount,
    ps.AvgScore,
    us.TotalUsers,
    us.AvgReputation,
    us.AvgViews,
    vs.TotalVotes,
    vs.UniqueVotedPosts,
    vs.UniqueVoters
FROM 
    PostStats ps,
    UserStats us,
    VoteStats vs;