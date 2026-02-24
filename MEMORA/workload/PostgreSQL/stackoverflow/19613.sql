SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    c.Text AS MostRecentComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  
ORDER BY 
    p.CreationDate DESC
LIMIT 10;