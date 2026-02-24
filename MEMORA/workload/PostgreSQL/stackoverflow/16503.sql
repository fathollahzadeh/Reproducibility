SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    ph.Comment AS EditComment,
    ph.CreationDate AS EditDate
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5) 
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;