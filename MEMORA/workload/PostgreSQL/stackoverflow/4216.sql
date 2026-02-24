WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.Upvotes,
    RP.Downvotes,
    UBadges.BadgeCount,
    UBadges.GoldBadges,
    UBadges.SilverBadges,
    UBadges.BronzeBadges
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.PostId = U.Id
LEFT JOIN 
    UserBadges UBadges ON U.Id = UBadges.UserId
WHERE 
    (RP.Upvotes - RP.Downvotes) > 0
    AND UBadges.BadgeCount IS NOT NULL
ORDER BY 
    RP.Rank, RP.Score DESC
FETCH FIRST 100 ROWS ONLY;