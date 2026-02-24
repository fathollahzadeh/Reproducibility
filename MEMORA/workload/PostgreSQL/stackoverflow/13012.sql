SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.CreationDate) AS MostRecentPost,
    MIN(p.CreationDate) AS OldestPost
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;