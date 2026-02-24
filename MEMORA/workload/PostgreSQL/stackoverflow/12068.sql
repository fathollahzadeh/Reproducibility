SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.CreationDate AS HistoryCreationDate,
    ph.Comment AS HistoryComment,
    ph.PostHistoryTypeId,
    ph.Text AS HistoryText
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId IN (1, 2) 
ORDER BY 
    p.Score DESC
LIMIT 10;