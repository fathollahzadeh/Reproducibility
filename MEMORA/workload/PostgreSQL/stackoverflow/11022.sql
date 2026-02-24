SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MIN(ph.CreationDate) AS FirstEditDate,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
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
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    PostScore DESC, PostViewCount DESC;
