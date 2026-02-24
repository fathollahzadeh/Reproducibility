SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;