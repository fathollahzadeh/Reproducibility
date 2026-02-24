SELECT 
    u.DisplayName AS UserDisplayName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
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
