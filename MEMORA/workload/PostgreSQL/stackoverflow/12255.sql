
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
