SELECT 
    pt.Name AS PostTypeName,
    AVG(p.Score) AS AverageScore,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;