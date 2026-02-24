
SELECT 
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(p.Score) AS AverageScore,
    u.Reputation AS UserReputation,
    p.CreationDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'  
GROUP BY 
    p.Id, p.Title, p.PostTypeId, u.Reputation, p.CreationDate
ORDER BY 
    AverageScore DESC
LIMIT 100;
