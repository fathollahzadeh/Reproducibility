WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) as TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
EngagedUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        UB.BadgeCount,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.AverageScore,
        PS.TotalViews
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    JOIN PostStats PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation > 1000
)
SELECT 
    EU.DisplayName, 
    EU.Reputation, 
    EU.BadgeCount, 
    EU.TotalPosts, 
    EU.Questions, 
    EU.Answers, 
    EU.AverageScore, 
    EU.TotalViews
FROM EngagedUsers EU
ORDER BY EU.Reputation DESC, EU.BadgeCount DESC
LIMIT 10;
