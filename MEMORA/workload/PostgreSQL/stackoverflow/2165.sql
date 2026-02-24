
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel,
        CreationDate
    FROM Users
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.ReputationLevel,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.AverageScore,
        DENSE_RANK() OVER (PARTITION BY ur.ReputationLevel ORDER BY ps.TotalPosts DESC) AS Rank
    FROM UserReputation ur
    JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT
    u.DisplayName,
    tu.ReputationLevel,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AverageScore,
    COALESCE(CAST(tu.Rank AS VARCHAR), 'N/A') AS PostRank,
    STRING_AGG(pt.Name, ', ') AS PostTypes
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
LEFT JOIN Posts p ON p.OwnerUserId = u.Id
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE tu.Rank <= 3 OR tu.ReputationLevel = 'Low'
GROUP BY u.DisplayName, tu.ReputationLevel, tu.TotalPosts, tu.Questions, tu.Answers, tu.AverageScore, tu.Rank
ORDER BY tu.ReputationLevel, tu.TotalPosts DESC;
