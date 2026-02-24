SELECT 
    PT.Name AS PostTypeName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT U.Id) AS TotalUsers,
    COUNT(DISTINCT T.TagName) AS TotalTags
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;