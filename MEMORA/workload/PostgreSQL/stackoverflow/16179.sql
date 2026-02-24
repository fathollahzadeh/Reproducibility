SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS HistoryCreationDate,
    pht.Name AS PostHistoryTypeName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate >= '2023-01-01'
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;
