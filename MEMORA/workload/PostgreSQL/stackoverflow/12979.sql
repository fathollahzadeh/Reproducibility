SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AvgScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostType;