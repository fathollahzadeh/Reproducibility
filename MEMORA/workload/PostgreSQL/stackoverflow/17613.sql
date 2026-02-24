
SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    u.DisplayName AS AuthorName, 
    p.CreationDate AS PostDate, 
    p.Score AS PostScore, 
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
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
