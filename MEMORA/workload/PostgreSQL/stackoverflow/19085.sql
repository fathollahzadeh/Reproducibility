SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts AS p
JOIN 
    Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
LEFT JOIN 
    Votes AS v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;