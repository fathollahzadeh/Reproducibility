
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostCounts
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(up.QuestionCount, 0) AS NumberOfQuestions,
    COALESCE(up.AnswerCount, 0) AS NumberOfAnswers,
    COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
FROM Users u
LEFT JOIN TopUsers up ON u.Id = up.UserId
LEFT JOIN Comments c ON c.UserId = u.Id
WHERE u.CreationDate < (DATE '2024-10-01' - INTERVAL '1 year')
GROUP BY u.Id, u.DisplayName, u.Reputation, up.QuestionCount, up.AnswerCount
HAVING COALESCE(up.QuestionCount, 0) + COALESCE(up.AnswerCount, 0) > 10
ORDER BY ReputationRank, NumberOfQuestions DESC
LIMIT 50;
