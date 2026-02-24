SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;