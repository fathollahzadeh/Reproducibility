SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalScore DESC
LIMIT 10;
