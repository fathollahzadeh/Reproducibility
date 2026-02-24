SELECT 
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViewCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Reputation
ORDER BY 
    TotalPosts DESC;