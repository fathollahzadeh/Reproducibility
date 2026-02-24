SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViewCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 100;