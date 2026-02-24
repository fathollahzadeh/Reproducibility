WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS UserPostViewCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount,
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.UserPostViewCount
FROM 
    PostStatistics PS
JOIN 
    Users U ON PS.PostTypeId = U.Id
JOIN 
    UserStatistics US ON U.Id = US.UserId
ORDER BY 
    PS.ViewCount DESC, PS.Score DESC;