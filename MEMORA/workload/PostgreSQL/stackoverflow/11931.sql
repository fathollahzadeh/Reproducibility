
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        STDDEV(P.Score) OVER() AS ScoreStdDev
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount,
    US.UserId,
    US.DisplayName,
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
    PS.Score DESC, PS.ViewCount DESC;
