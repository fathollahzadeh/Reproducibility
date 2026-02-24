
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) AS AverageUpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END) AS AverageDownVotes,
    ph.UserDisplayName AS LastEditedBy,
    ph.CreationDate AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, 
    u.DisplayName, u.Reputation, ph.UserDisplayName, ph.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
