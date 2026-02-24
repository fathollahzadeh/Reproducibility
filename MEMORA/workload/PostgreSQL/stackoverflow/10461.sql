SELECT 
    u.Id AS UserId,
    u.DisplayName,
    AVG(p.Score) AS AverageQuestionScore,
    COUNT(p.Id) AS TotalQuestions
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    AverageQuestionScore DESC
LIMIT 10;