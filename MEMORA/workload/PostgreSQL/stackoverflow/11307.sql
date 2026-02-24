SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    c.Id AS CommentID,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'
ORDER BY 
    p.CreationDate DESC, c.CreationDate DESC
LIMIT 1000;