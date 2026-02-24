SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    COUNT(c.Id) AS CommentCount,
    p.CreationDate AS PostDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate
ORDER BY 
    CommentCount DESC
LIMIT 10;