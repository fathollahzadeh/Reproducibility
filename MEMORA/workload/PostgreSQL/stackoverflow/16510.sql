SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;