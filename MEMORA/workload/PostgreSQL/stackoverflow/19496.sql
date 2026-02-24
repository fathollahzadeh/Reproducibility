SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'
ORDER BY 
    p.Score DESC
LIMIT 10;
