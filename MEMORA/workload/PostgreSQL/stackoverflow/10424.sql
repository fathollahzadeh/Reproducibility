
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate,
    p.LastActivityDate,
    u.DisplayName AS UserDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.Score, p.CreationDate, p.LastActivityDate, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 100;
