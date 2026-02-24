WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND P.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        RP.PostId,
        RP.Title,
        RP.CreationDate AS PostCreatedDate,
        RP.Score
    FROM UserBadgeCounts U
    JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
    WHERE RP.rn = 1
    ORDER BY U.BadgeCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.BadgeCount,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    TU.Title AS RecentPostTitle,
    TU.PostCreatedDate,
    TU.Score
FROM TopUsers TU
ORDER BY TU.BadgeCount DESC, TU.Score DESC;