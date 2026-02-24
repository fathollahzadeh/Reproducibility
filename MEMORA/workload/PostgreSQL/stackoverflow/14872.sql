
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        U.Reputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    U.UserId,
    U.PostCount,
    U.AvgScore,
    U.Reputation
FROM 
    UserPostStats U
ORDER BY 
    U.Reputation DESC
LIMIT 10;
