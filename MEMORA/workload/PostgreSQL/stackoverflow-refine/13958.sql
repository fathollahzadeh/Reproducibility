SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.UserId) AS VoteCount,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 ELSE 0 END) AS AcceptedVotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    p.CreationDate DESC;
