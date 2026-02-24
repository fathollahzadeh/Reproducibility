SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC, COUNT(c.Id) DESC
LIMIT 100;
