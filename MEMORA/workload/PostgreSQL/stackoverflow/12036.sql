SELECT 
    COUNT(DISTINCT P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    AVG(P.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT U.Id) AS TotalUsers
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'  