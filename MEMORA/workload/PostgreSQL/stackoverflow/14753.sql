SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE NULL END) AS AverageScore,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;