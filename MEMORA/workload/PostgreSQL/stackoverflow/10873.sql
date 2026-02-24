
SELECT 
    u.Id AS UserId,
    u.Reputation,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY 
    u.Id, u.Reputation, p.Id, p.Title, p.CreationDate, p.ViewCount
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC
LIMIT 100;
