SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(c.Score) AS TotalCommentScore,
    COUNT(c.Id) AS TotalComments,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;