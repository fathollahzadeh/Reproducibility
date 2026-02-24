SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS HistoryCreationDate,
    p.Body AS PostBody,
    ph.Comment AS EditComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;