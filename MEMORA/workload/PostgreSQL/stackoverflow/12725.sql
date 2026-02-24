
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.PostCount,
        u.VoteCount,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
    FROM UserPostCounts u
    JOIN Users us ON u.UserId = us.Id
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    VoteCount,
    ReputationRank
FROM RankedUsers
WHERE ReputationRank <= 10
ORDER BY ReputationRank;
