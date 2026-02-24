SELECT 
    u.DisplayName,
    p.Title,
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    u.DisplayName, p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;
