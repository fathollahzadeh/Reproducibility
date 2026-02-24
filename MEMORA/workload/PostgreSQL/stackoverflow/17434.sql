SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    ph.CreationDate AS HistoryDate, 
    p.Score AS PostScore, 
    COUNT(c.Id) AS CommentCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
JOIN 
    PostHistory ph ON p.Id = ph.PostId 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
WHERE 
    ph.PostHistoryTypeId IN (1, 2, 4) 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    ph.CreationDate, 
    p.Score 
ORDER BY 
    ph.CreationDate DESC;