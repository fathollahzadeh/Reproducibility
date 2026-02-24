
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
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
CombinedData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        RP.PostId,
        RP.Title AS RecentPostTitle,
        RP.CreationDate AS RecentPostDate,
        RP.Score AS RecentPostScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.PostRank = 1
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.BadgeCount,
    C.GoldBadges,
    C.SilverBadges,
    C.BronzeBadges,
    C.RecentPostTitle,
    C.RecentPostDate,
    C.RecentPostScore
FROM CombinedData C
WHERE 
    (C.BadgeCount > 0 OR C.RecentPostTitle IS NOT NULL)
ORDER BY 
    C.BadgeCount DESC,
    C.RecentPostDate DESC
FETCH FIRST 10 ROWS ONLY;
