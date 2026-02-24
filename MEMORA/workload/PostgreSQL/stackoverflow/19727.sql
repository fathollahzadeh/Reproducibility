
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS Owner,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
