SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS UserName,
    p.Score,
    p.CreationDate
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
LIMIT 10;