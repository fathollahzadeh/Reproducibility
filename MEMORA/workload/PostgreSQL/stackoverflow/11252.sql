
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount,
    AVG(EXTRACT(EPOCH FROM (v.CreationDate - p.CreationDate))) AS AvgTimeToVote
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    p.CommentCount, p.AnswerCount, u.Id, u.DisplayName, 
    u.Reputation, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC;
