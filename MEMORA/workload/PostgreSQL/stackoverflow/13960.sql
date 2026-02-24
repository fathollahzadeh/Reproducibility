
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.TotalScore,
    US.BadgeCount,
    PS.PostType,
    PS.TotalPosts,
    PS.AvgViewCount,
    PS.AvgScore
FROM 
    UserStats US
CROSS JOIN 
    PostStats PS
ORDER BY 
    US.Reputation DESC, 
    US.TotalScore DESC, 
    PS.AvgViewCount DESC;
