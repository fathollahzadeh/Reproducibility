SELECT 
    p.Title, 
    u.DisplayName AS Author,
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    COALESCE( (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
LIMIT 10;