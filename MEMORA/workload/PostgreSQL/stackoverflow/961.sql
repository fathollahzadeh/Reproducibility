
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.DisplayName,
        ps.OwnerUserId,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.AverageScore
    FROM UserReputation ur
    JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
    WHERE ur.Reputation > 1000
    ORDER BY ur.Reputation DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
    COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ps.AverageScore, 0) AS AvgPostScore,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.OwnerUserId AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.OwnerUserId AND b.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.OwnerUserId AND b.Class = 3) AS BronzeBadges
FROM TopUsers tu
LEFT JOIN PostStatistics ps ON tu.OwnerUserId = ps.OwnerUserId
WHERE (ps.PostCount > 5 OR ps.QuestionCount > 0)
ORDER BY TotalQuestions DESC, TotalAnswers DESC;
