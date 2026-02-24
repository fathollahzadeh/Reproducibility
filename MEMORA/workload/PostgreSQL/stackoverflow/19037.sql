SELECT 
    p.Title AS PostTitle, 
    u.DisplayName AS Author, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
