
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
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
    p.Title, 
    p.CreationDate, 
    u.DisplayName 
ORDER BY 
    VoteCount DESC 
LIMIT 10;
