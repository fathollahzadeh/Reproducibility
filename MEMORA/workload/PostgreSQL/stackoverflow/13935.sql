SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.CommentCount) AS AverageComments, 
    AVG(p.ViewCount) AS AverageViews,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'  
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;