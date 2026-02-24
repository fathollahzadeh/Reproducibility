SELECT 
    p.Id AS PostId, 
    p.Title, 
    pt.Name AS PostType, 
    u.DisplayName AS Owner, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score 
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.Score > 0
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
