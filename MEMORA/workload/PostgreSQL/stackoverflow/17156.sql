
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Owner,
    COUNT(a.Id) AS AnswerCount,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
