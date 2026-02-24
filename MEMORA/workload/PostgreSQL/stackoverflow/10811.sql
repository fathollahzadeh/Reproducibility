
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    u.Reputation AS UserReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
