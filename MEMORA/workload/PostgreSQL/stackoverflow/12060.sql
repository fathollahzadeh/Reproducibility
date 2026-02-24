WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViewCount
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

VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        AVG(VoteCount) AS AverageVotesPerPost
    FROM (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS PostVoteCounts
)

SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT AverageViewCount FROM PostStats) AS AverageViewCount,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AverageReputation FROM UserStats) AS AverageReputation,
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes,
    (SELECT AverageVotesPerPost FROM VoteStats) AS AverageVotesPerPost;