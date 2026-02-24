SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AveragePostScore,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.Score IS NOT NULL
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;