
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Author, 
    u.Reputation, 
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
    p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
