SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC, 
    AveragePostScore DESC
LIMIT 100;