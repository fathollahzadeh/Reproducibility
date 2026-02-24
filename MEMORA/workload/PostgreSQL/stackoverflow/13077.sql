SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.Score,
    p.CreationDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 0 
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC
LIMIT 100;