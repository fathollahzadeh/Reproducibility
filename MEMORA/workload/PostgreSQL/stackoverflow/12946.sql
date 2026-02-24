SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.ViewCount) AS AverageViews,
    (SELECT COUNT(DISTINCT u.Id) FROM Users u) AS TotalUsers,
    (SELECT COUNT(b.Id) FROM Badges b) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;