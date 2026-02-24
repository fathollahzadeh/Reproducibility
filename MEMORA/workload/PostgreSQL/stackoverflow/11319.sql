SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    ph.CreationDate AS HistoryCreationDate,
    ph.Comment AS HistoryComment,
    ph2.UserDisplayName AS EditorName,
    ph2.CreationDate AS EditCreationDate,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistory ph2 ON ph.PostId = ph2.PostId AND ph2.PostHistoryTypeId IN (4, 5, 6)
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    u.DisplayName, p.Title, ph.CreationDate, ph.Comment, ph2.UserDisplayName, ph2.CreationDate
ORDER BY 
    TotalVotes DESC, ph.CreationDate DESC;