SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId IN (1, 2) 
GROUP BY 
    p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC
LIMIT 100;