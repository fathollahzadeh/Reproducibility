WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.OwnerUserId, P.Score, P.ViewCount
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    PS.PostId,
    PS.PostTypeId,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount
FROM 
    Users U
JOIN 
    UserBadges UB ON U.Id = UB.UserId
JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC, 
    PS.Score DESC;