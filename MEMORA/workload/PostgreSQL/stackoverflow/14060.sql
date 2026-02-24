SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(ph.Id) AS HistoryCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2022-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
