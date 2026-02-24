SELECT 
    u.Id AS UserId,
    u.DisplayName,
    AVG(u.Reputation) AS AvgReputation,
    COUNT(p.Id) AS PostCount,
    MAX(p.Score) AS MaxScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.Score > 0
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    AvgReputation DESC
LIMIT 10;