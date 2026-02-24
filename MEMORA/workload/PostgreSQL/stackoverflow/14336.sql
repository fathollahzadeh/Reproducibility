
WITH PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation
    FROM 
        Users
),
PostStats AS (
    SELECT 
        u.UserId,
        u.Reputation,
        pc.TotalPosts,
        pc.TotalQuestions,
        pc.TotalAnswers
    FROM 
        PostCounts pc
    JOIN 
        UserReputation u ON pc.OwnerUserId = u.UserId
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    (CAST(TotalQuestions AS FLOAT) / NULLIF(TotalPosts, 0)) * 100 AS QuestionPercentage,
    (CAST(TotalAnswers AS FLOAT) / NULLIF(TotalPosts, 0)) * 100 AS AnswerPercentage
FROM 
    PostStats
ORDER BY 
    Reputation DESC;
