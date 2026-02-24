SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    COALESCE(AVG(p.Score), 0) AS AverageScore,
    u.Reputation AS UserReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC;