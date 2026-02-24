SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;