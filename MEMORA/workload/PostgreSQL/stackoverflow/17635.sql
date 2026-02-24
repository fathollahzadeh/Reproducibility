
SELECT 
    p.Title, 
    u.DisplayName AS Owner, 
    COUNT(c.Id) AS CommentCount, 
    p.CreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
