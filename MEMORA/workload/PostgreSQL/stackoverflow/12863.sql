SELECT 
    P.PostTypeId,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
GROUP BY 
    P.PostTypeId
ORDER BY 
    P.PostTypeId;