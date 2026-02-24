
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COALESCE(pt.Name, 'Unknown') AS PostType,
    COALESCE(ut.Reputation, 0) AS OwnerReputation,
    COALESCE(ut.DisplayName, 'Anonymous') AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users ut ON p.OwnerUserId = ut.Id
WHERE 
    p.CreationDate >= DATE '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name, ut.Reputation, ut.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
