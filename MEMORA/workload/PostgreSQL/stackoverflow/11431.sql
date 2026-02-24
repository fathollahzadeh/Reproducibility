
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.Reputation AS UserReputation,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, u.Reputation
ORDER BY 
    p.Score DESC,          
    UserReputation DESC    
LIMIT 
    100;
