
SELECT 
    p.Title,
    u.DisplayName AS Author,
    p.CreationDate,
    p.ViewCount,
    COUNT(a.Id) AS AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
