
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    u.DisplayName AS OwnerName,
    COUNT(c.Id) AS CommentCount,
    p.CreationDate AS CreationDate,
    p.Score AS PostScore
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 10;
