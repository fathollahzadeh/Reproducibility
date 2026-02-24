SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AvgUserReputation,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;