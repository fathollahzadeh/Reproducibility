WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        AVG(v.VoteCount) AS AverageVotes,
        SUM(u.Reputation) AS TotalReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id
)

SELECT 
    ups.UserId,
    ups.PostCount,
    COALESCE(ups.AverageVotes, 0) AS AverageVotes,
    ups.TotalReputation
FROM UserPostStats ups
ORDER BY ups.TotalReputation DESC
LIMIT 10;