WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUniqueUsers
    FROM 
        Posts
),
UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
AvgVoteCount AS (
    SELECT 
        AVG(VoteCount) AS AverageVotesPerUser
    FROM 
        UserVoteCounts
)

SELECT 
    pc.TotalPosts,
    pc.TotalUniqueUsers,
    av.AverageVotesPerUser
FROM 
    PostCounts pc,
    AvgVoteCount av;