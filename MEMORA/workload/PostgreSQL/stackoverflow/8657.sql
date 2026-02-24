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
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName
    ORDER BY P.ViewCount DESC
    LIMIT 5
)
SELECT 
    UB.DisplayName AS UserName,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViews,
    PP.CommentCount AS PopularPostComments
FROM UserBadges UB
JOIN PopularPosts PP ON PP.CommentCount > 0
ORDER BY UB.BadgeCount DESC, PP.ViewCount DESC;