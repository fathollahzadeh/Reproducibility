
SELECT 
    PT.Name AS PostType, 
    COUNT(P.Id) AS TotalPosts, 
    SUM(P.Score) AS TotalScore, 
    AVG(P.ViewCount) AS AverageViews, 
    COUNT(DISTINCT C.Id) AS TotalComments, 
    SUM(V.BountyAmount) AS TotalBounty
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId 
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;
