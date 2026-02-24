SELECT 
    p.Id as PostId, 
    p.Title, 
    u.DisplayName as OwnerDisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 /* Only questions */ 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
