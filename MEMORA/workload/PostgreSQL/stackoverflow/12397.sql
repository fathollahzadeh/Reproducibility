SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.ViewCount) AS AverageViewCount, 
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS TotalScoredPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;