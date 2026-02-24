SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    ph.CreationDate AS HistoryCreationDate,
    p.Score AS PostScore
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId = 4 
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;