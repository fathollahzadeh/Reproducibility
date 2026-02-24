WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2022-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.VoteCount,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.ViewCount DESC 
LIMIT 100;