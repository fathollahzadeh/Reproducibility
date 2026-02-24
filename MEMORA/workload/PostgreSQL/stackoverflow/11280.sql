WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        P.PostTypeId,
        U.Id AS UserId,
        U.Reputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.OwnerUserId IS NOT NULL
)
SELECT 
    P.Name AS PostTypeName,
    PS.PostCount,
    PS.AvgScore,
    PS.AvgViewCount,
    MAX(U.Reputation) AS HighestUserReputation
FROM 
    PostStats PS
JOIN 
    PostTypes P ON PS.PostTypeId = P.Id
LEFT JOIN 
    UserStats U ON PS.PostTypeId = U.PostTypeId
GROUP BY 
    P.Name, PS.PostCount, PS.AvgScore, PS.AvgViewCount
ORDER BY 
    PS.PostCount DESC;