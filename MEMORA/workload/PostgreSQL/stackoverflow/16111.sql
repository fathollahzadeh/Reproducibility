SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate AS CreationDate, 
    p.ViewCount AS ViewCount, 
    p.Score AS Score 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
