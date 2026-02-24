SELECT 
    u.DisplayName AS UserDisplayName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
    p.Score AS PostScore, 
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC
LIMIT 10;