WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    UR.CommentCount,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PS.TotalViews,
    PS.AverageScore
FROM 
    Users U
JOIN 
    UserReputation UR ON U.Id = UR.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
ORDER BY 
    UR.Reputation DESC, PS.TotalPosts DESC
LIMIT 100;