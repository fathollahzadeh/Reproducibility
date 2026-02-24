SELECT 
    ph.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    ph.PostHistoryTypeId,
    p.OwnerUserId,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    ph.CreationDate >= '2023-01-01' 
GROUP BY 
    ph.PostId, p.Title, p.CreationDate, p.Score, ph.PostHistoryTypeId, p.OwnerUserId
ORDER BY 
    p.CreationDate DESC;
