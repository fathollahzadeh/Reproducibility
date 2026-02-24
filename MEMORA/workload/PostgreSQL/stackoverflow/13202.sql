
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COALESCE(ub.Reputation, 0) AS OwnerReputation,
    COALESCE(up.Reputation, 0) AS LastEditorReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users ub ON p.OwnerUserId = ub.Id
LEFT JOIN 
    Users up ON p.LastEditorUserId = up.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, ub.Reputation, up.Reputation
ORDER BY 
    p.CreationDate DESC;
