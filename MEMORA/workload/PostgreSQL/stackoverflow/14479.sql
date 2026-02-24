WITH UserParticipation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AverageReputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    AVG(AverageReputation) AS OverallAverageReputation,
    SUM(PostCount) AS TotalPostsByUsers,
    SUM(VoteCount) AS TotalVotesByUsers
FROM 
    UserParticipation;