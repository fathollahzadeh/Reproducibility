WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCount UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.BadgeCount,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.AvgScore, 0) AS AvgScore,
    COALESCE(PS.TotalViews, 0) AS TotalViews
FROM TopUsers TU
LEFT JOIN PostStats PS ON TU.Id = PS.OwnerUserId
WHERE TU.BadgeCount > 0
ORDER BY TU.Reputation DESC, TU.BadgeCount DESC;