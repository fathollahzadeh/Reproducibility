
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= '2023-01-01' 
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    PS.PostId,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount,
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.TotalViews,
    US.AveragePostScore
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId = U.Id
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, 
    US.Reputation DESC;
