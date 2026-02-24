
SELECT 
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    pt.Name AS PostTypeName,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
