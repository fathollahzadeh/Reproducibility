WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.Score, P.ViewCount
    HAVING COUNT(C.Id) > 10
    ORDER BY P.Score DESC
    LIMIT 5
)
SELECT 
    U.DisplayName,
    PB.Title,
    PB.Score,
    PB.ViewCount,
    UBad.BadgeCount,
    UBad.GoldBadges,
    UBad.SilverBadges,
    UBad.BronzeBadges
FROM PopularPosts PB
JOIN Users U ON PB.OwnerUserId = U.Id
JOIN UserBadges UBad ON U.Id = UBad.UserId
ORDER BY PB.Score DESC, UBad.BadgeCount DESC;