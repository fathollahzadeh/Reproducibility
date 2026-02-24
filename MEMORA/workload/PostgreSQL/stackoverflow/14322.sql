
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    pt.Name AS PostType,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, pt.Name, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC 
LIMIT 100 OFFSET 0;
