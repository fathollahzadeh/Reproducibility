SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AvgUserReputation,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore
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