SELECT 
    ph.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate,
    u.DisplayName AS EditorDisplayName
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;