WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TrendingUsers AS (
    SELECT 
        UB.UserId,
        UB.BadgeCount,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY UB.Reputation DESC, UB.BadgeCount DESC) AS Rank
    FROM UserBadges UB
    JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
    WHERE UB.Reputation > 1000 
    AND PS.TotalPosts > 5 
)

SELECT 
    U.DisplayName,
    TU.Rank,
    TU.BadgeCount,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AvgViewCount
FROM TrendingUsers TU
JOIN Users U ON TU.UserId = U.Id
WHERE TU.Rank <= 10
ORDER BY TU.Rank;