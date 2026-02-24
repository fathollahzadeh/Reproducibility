SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
    COALESCE(SUM(P.Score), 0) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalScore DESC, PostCount DESC;