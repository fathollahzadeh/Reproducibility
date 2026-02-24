SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS UserCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;