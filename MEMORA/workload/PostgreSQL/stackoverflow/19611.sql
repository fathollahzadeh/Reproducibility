SELECT 
    p.Id AS PostId, 
    p.Title, 
    u.DisplayName AS OwnerName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    COALESCE(c.CommentCount, 0) AS CommentCount
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