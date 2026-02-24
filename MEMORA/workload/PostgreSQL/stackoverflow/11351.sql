WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserReputationScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(up.PostCount, 0) AS PostCount,
        COALESCE(up.QuestionCount, 0) AS QuestionCount,
        COALESCE(up.AnswerCount, 0) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        UserPostCounts up ON u.Id = up.UserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    (u.Reputation / NULLIF(u.PostCount, 0)) AS ReputationPerPost,
    (u.Reputation / NULLIF(u.QuestionCount, 0)) AS ReputationPerQuestion,
    (u.Reputation / NULLIF(u.AnswerCount, 0)) AS ReputationPerAnswer
FROM 
    UserReputationScores u
ORDER BY 
    u.Reputation DESC
LIMIT 10;