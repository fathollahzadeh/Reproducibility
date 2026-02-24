
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COALESCE(a.Id, 0) AS AcceptedAnswerId,
    u.DisplayName AS OwnerDisplayName
FROM
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, a.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
