SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(c.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount
     FROM 
        Comments
     GROUP BY 
        PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;