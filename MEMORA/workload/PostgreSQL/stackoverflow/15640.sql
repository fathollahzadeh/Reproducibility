SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostDate, 
    ph.UserDisplayName AS EditorName, 
    ph.CreationDate AS EditDate, 
    ph.Comment AS EditComment
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5)  
ORDER BY 
    p.CreationDate DESC
LIMIT 10;