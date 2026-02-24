
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
),
AverageReputation AS (
    SELECT AVG(Reputation) AS AvgReputation FROM Users
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        BadgeCount,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        (Reputation - (SELECT AvgReputation FROM AverageReputation)) AS ReputationDifference
    FROM UserStats
    WHERE Reputation > (SELECT AvgReputation FROM AverageReputation)
    ORDER BY Reputation DESC
    LIMIT 10
)
SELECT 
    us.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    tu.ReputationDifference
FROM TopUsers tu
JOIN Users us ON tu.UserId = us.Id;
