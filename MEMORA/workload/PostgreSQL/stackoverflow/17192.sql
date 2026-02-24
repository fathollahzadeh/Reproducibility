SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    postType.Name AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes postType ON p.PostTypeId = postType.Id
WHERE 
    p.ViewCount > 100
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
