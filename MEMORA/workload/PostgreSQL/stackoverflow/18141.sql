SELECT 
    u.DisplayName, 
    u.Reputation, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
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
    u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;