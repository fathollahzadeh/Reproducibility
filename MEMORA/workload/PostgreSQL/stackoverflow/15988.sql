SELECT 
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    SUM(COALESCE(P.Score, 0)) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalScore DESC
LIMIT 10;
