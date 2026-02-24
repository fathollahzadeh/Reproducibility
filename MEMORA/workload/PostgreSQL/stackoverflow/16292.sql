
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
