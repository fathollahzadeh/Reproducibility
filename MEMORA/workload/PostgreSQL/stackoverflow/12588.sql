WITH PostCounts AS (
    SELECT 
        OwnerUserId,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    WHERE
        OwnerUserId IS NOT NULL 
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        PC.QuestionCount,
        PC.AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        PostCounts PC ON U.Id = PC.OwnerUserId
)
SELECT 
    AVG(CASE WHEN QuestionCount > 0 THEN Reputation END) AS AvgReputationForQuestions,
    AVG(CASE WHEN AnswerCount > 0 THEN Reputation END) AS AvgReputationForAnswers,
    COUNT(DISTINCT CASE WHEN QuestionCount > 0 THEN UserId END) AS TotalQuestionCreators,
    COUNT(DISTINCT CASE WHEN AnswerCount > 0 THEN UserId END) AS TotalAnswerCreators
FROM 
    UserReputation;