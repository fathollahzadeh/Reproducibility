
SELECT 
    p.Title, 
    u.DisplayName AS OwnerName, 
    p.CreationDate, 
    p.Score, 
    COUNT(com.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments com ON p.Id = com.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
