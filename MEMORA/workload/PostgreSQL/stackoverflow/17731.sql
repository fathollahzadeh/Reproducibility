
SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate AS PostCreationDate, 
    p.Score AS PostScore, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
