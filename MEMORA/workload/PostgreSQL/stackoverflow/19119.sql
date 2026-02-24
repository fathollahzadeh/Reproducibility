SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate,
    p.Score,
    c.Text AS CommentText,
    c.CreationDate AS CommentDate
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    Users u ON c.UserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
LIMIT 10;