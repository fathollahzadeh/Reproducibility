SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS HistoryCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
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
    ph.PostHistoryTypeId = 24 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, ph.CreationDate, p.Score, p.ViewCount
ORDER BY 
    ph.CreationDate DESC;