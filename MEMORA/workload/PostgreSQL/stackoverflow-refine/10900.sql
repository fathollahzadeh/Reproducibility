WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        SUM(p.ViewCount) AS TotalViewCount,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
)

SELECT 
    COUNT(*) AS TotalUsers,
    AVG(AvgReputation) AS AverageReputation,
    SUM(TotalViewCount) AS TotalViewsAcrossUsers,
    SUM(TotalVotes) AS TotalVotesAcrossUsers
FROM UserPostStats;