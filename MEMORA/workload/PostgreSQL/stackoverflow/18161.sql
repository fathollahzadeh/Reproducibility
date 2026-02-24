
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    COUNT(a.Id) AS AnswerCount, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId 
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, 
    p.CreationDate, 
    u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
