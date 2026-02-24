SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    ph.UserDisplayName AS LastEditorDisplayName,
    ph.CreationDate AS LastEditDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    pt.Name AS PostTypeName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.LastEditorUserId = ph.UserId AND p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName, ph.UserDisplayName, ph.CreationDate, pt.Name
ORDER BY 
    p.ViewCount DESC;
