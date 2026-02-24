WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalPostScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    US.BadgeCount,
    US.TotalBountyAmount,
    PS.PostCount,
    PS.TotalPostScore,
    PS.AverageViewCount
FROM 
    Users U
LEFT JOIN 
    UserStatistics US ON U.Id = US.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC;