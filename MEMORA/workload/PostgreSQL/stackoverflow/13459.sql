SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  
WHERE 
    p.CreationDate >= '2023-01-01'  
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 100;