SELECT 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    c.CommentCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId 
WHERE 
    p.PostTypeId = 1  
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;