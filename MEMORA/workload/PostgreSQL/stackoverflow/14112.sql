WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts, 
        AVG(Score) AS AverageScore,
        OwnerUserId
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation
    FROM 
        Users U
    JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    PS.TotalPosts, 
    PS.AverageScore, 
    UR.UserId, 
    UR.Reputation
FROM 
    PostStats PS
JOIN 
    UserReputation UR ON PS.OwnerUserId = UR.UserId 
ORDER BY 
    UR.Reputation DESC
LIMIT 10;