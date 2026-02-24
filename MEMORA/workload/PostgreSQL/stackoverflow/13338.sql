
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
    SUM(p.AnswerCount) AS TotalAnswersReceived
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id 
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalQuestions DESC
LIMIT 10;
