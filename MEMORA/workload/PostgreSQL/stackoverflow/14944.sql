WITH PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(pc.PostCount, 0) AS TotalPosts,
        COALESCE(pc.QuestionCount, 0) AS TotalQuestions,
        COALESCE(pc.AnswerCount, 0) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        PostCounts pc ON u.Id = pc.OwnerUserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    CASE 
        WHEN u.TotalPosts > 0 THEN (u.Reputation / u.TotalPosts)
        ELSE 0 
    END AS ReputationPerPost,
    CASE 
        WHEN u.TotalQuestions > 0 THEN (u.Reputation / u.TotalQuestions)
        ELSE 0 
    END AS ReputationPerQuestion,
    CASE 
        WHEN u.TotalAnswers > 0 THEN (u.Reputation / u.TotalAnswers)
        ELSE 0 
    END AS ReputationPerAnswer
FROM 
    UserReputation u
ORDER BY 
    u.Reputation DESC
LIMIT 100;