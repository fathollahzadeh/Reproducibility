SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    u.DisplayName AS OwnerName, 
    p.CreationDate AS PostCreationDate, 
    p.Score AS PostScore, 
    p.ViewCount AS PostViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;