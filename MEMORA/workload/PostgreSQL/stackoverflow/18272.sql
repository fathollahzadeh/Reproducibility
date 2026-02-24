SELECT 
    p.Id AS PostID, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    u.DisplayName AS Author, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
