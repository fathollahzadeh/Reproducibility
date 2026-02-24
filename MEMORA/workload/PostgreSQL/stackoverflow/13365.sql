
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(u.Reputation) AS AverageOwnerReputation,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
