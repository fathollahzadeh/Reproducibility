SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate,
    u.DisplayName AS CommenterDisplayName,
    v.CreationDate AS VoteCreationDate,
    vt.Name AS VoteTypeName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    Users u ON c.UserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC, 
    c.CreationDate DESC, 
    v.CreationDate DESC
LIMIT 100;