WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.PostCount,
    UPS.AverageScore,
    UPS.TotalComments
FROM 
    UserPostStats UPS
ORDER BY 
    UPS.PostCount DESC, 
    UPS.AverageScore DESC
LIMIT 100;