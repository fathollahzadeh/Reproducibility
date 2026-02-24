SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionCreationDate,
    COALESCE(AVG(a.CreationDate - p.CreationDate), INTERVAL '0 seconds') AS AverageResponseTime,
    COUNT(a.Id) AS TotalAnswers
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    AverageResponseTime DESC;