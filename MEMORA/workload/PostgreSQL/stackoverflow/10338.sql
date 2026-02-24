
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, U.Id, U.Reputation
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CreationDate,
    PS.UserId,
    PS.Reputation,
    US.PostCount,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges,
    PS.CommentCount,
    PS.VoteCount,
    PS.Upvotes,
    PS.Downvotes
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.UserId = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
