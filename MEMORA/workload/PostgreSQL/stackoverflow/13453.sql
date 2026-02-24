SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT P.OwnerUserId) AS DistinctUsers
FROM 
    Posts P
WHERE 
    P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year';