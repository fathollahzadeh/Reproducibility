SELECT 
    pt.Name AS PostType,
    u.Reputation AS UserReputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, 
    u.Reputation
ORDER BY 
    pt.Name, 
    u.Reputation;