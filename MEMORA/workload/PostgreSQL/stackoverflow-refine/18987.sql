SELECT 
    u.DisplayName, 
    p.Title, 
    COUNT(c.Id) as CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;