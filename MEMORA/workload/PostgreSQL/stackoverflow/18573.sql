
SELECT 
    p.Title, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    COUNT(v.Id) AS VoteCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, p.Score 
ORDER BY 
    p.Score DESC 
LIMIT 10;
