SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    COUNT(v.Id) AS VoteCount, 
    COUNT(c.Id) AS CommentCount, 
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score
ORDER BY 
    VoteCount DESC, 
    CommentCount DESC, 
    PostHistoryCount DESC
LIMIT 100;
