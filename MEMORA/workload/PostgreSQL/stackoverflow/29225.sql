
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS UserPostRank,
        P.OwnerUserId
    FROM 
        Posts P 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.LastActivityDate, P.ViewCount, P.AnswerCount, P.OwnerUserId
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        U.Reputation
    FROM 
        Users U 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    UP.DisplayName,
    UP.Reputation,
    UP.GoldBadges,
    UP.SilverBadges,
    UP.BronzeBadges,
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CommentCount,
    RP.VoteCount,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.ViewCount,
    RP.AnswerCount,
    RP.UserPostRank
FROM 
    RankedPosts RP
JOIN 
    UserReputation UP ON RP.UserPostRank = 1 AND UP.UserId = RP.OwnerUserId
WHERE 
    RP.CommentCount > 5 
ORDER BY 
    UP.Reputation DESC, 
    RP.VoteCount DESC
LIMIT 10;
