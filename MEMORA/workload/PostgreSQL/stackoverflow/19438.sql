
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS Author,
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
    p.Id, p.Title, p.Score, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 10;
