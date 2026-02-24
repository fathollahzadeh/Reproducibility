SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.CreationDate AS PostDate,
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
    u.DisplayName, p.Title, p.Score, p.CreationDate
ORDER BY 
    p.Score DESC;