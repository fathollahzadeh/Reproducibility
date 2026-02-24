WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalViews,
        PS.TotalScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE U.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore
FROM ActiveUsers
ORDER BY TotalScore DESC, Reputation DESC
LIMIT 10;