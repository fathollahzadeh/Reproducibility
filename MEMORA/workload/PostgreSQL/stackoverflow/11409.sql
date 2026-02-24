
SELECT 
    p.Id AS PostID,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    p.AnswerCount,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) AS AverageUpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END) AS AverageDownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.AnswerCount, u.Reputation
ORDER BY 
    p.CreationDate DESC;
