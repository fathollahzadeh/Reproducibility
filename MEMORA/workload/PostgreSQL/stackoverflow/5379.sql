
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(P.ViewCount) AS AverageViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.PositivePosts,
        US.NegativePosts,
        US.PopularPosts,
        US.AverageViews,
        COALESCE(BS.BadgeCount, 0) AS BadgeCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM UserStats US
    LEFT JOIN BadgeStats BS ON US.UserId = BS.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    PositivePosts,
    NegativePosts,
    PopularPosts,
    AverageViews,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM CombinedStats
WHERE Reputation > 1000
ORDER BY Reputation DESC, PostCount DESC
LIMIT 50;
