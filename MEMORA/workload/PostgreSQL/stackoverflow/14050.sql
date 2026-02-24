
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
