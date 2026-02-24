SELECT 
    p.Title, 
    u.DisplayName as Owner, 
    p.Score, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.Score DESC 
LIMIT 10;
