
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.AcceptedAnswerId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, a.AcceptedAnswerId
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
