
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, 
    p.CommentCount, p.Score, u.Id, u.DisplayName, u.Reputation, 
    u.CreationDate, u.LastAccessDate
ORDER BY 
    p.ViewCount DESC, p.CreationDate DESC
LIMIT 100;
