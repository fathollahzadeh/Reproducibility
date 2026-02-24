SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostType,
    ARRAY_AGG(DISTINCT lt.Name) AS LinkType
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE 
    p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;