
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
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS rn
    FROM Posts P
    WHERE P.PostTypeId = 1
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(P.Score), 0) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PS.TotalPosts,
    PS.TotalScore,
    PS.TotalViews,
    PS.AverageScore,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViews
FROM UserBadges U
JOIN UserPostStats PS ON U.UserId = PS.UserId
LEFT JOIN TopPosts TP ON U.UserId = TP.OwnerUserId AND TP.rn = 1
ORDER BY U.BadgeCount DESC, PS.TotalScore DESC;
