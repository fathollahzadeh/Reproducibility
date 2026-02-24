
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score, p.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
