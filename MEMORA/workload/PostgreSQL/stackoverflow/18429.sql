SELECT 
    p.Id AS PostID, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
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