
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel,
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserScore
    WHERE ReputationLevel = 'High' AND QuestionsCount > 5
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Posts p
    WHERE p.PostTypeId = 1
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionsCount,
    qs.TotalQuestions,
    qs.AcceptedQuestions,
    qs.AverageScore,
    (tu.UpVotesCount - tu.DownVotesCount) AS NetVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = tu.UserId) AS CommentCount
FROM TopUsers tu
LEFT JOIN QuestionStats qs ON tu.UserId = qs.OwnerUserId
WHERE (tu.UpVotesCount > 10 OR tu.DownVotesCount < 5)
ORDER BY tu.Reputation DESC, qs.AverageScore DESC
LIMIT 50;
