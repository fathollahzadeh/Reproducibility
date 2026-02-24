WITH PostStats AS (
    SELECT 
        DATE_TRUNC('month', CreationDate) AS Month,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        SUM(VoteCount) AS TotalVotes
    FROM 
        Posts
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteCounts ON Posts.Id = VoteCounts.PostId
    GROUP BY 
        Month
),
UserStats AS (
    SELECT 
        DATE_TRUNC('month', CreationDate) AS Month,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation
    FROM 
        Users
    GROUP BY 
        Month
)
SELECT 
    ps.Month,
    ps.TotalPosts,
    ps.UniqueUsers,
    ps.TotalVotes,
    us.TotalUsers,
    us.TotalReputation
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.Month = us.Month
ORDER BY 
    ps.Month DESC;