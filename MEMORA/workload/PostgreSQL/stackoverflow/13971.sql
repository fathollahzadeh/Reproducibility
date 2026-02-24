SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(pa.Id) AS TotalAcceptedAnswers
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Posts pa ON p.AcceptedAnswerId = pa.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;