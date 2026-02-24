
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerName,
    p.CreationDate,
    p.Score,
    COUNT(co.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments co ON p.Id = co.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC
LIMIT 10;
