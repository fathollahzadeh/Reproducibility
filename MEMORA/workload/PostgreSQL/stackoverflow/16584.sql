SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostDate, 
    COUNT(c.Id) AS CommentCount 
FROM 
    Users AS u
JOIN 
    Posts AS p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate
ORDER BY 
    PostDate DESC
LIMIT 10;
