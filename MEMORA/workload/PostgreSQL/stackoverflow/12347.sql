SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    COUNT(DISTINCT V.UserId) AS TotalUniqueVoters
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2020-01-01'  
AND 
    P.PostTypeId = 1;