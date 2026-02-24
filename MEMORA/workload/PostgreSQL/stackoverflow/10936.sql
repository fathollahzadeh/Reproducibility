
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    p.LastActivityDate,
    p.AcceptedAnswerId,
    ph.CreationDate AS PostHistoryDate,
    p.Body
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Reputation, u.DisplayName, 
    p.LastActivityDate, p.AcceptedAnswerId, ph.CreationDate, p.Body
ORDER BY 
    p.Score DESC;
