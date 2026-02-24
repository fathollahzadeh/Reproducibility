SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1
ORDER BY 
    p.Score DESC
LIMIT 10;
