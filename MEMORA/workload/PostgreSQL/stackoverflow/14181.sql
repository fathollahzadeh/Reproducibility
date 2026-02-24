
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts AS p
JOIN 
    PostTypes AS pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
