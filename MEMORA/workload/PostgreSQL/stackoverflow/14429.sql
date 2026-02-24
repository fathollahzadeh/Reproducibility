SELECT 
    PT.Name AS PostType,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT V.Id) AS TotalVotes,
    COUNT(DISTINCT C.Id) AS TotalComments
FROM 
    PostTypes PT
LEFT JOIN 
    Posts P ON P.PostTypeId = PT.Id
LEFT JOIN 
    Votes V ON V.PostId = P.Id
LEFT JOIN 
    Comments C ON C.PostId = P.Id
GROUP BY 
    PT.Id, PT.Name
ORDER BY 
    TotalPosts DESC;