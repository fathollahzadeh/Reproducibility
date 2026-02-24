SELECT 
    u.DisplayName,
    p.Title,
    p.Score,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.Score, p.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;