WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
UserPostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Location,
    U.CreationDate,
    COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
    COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(UPS.TotalPosts, 0) AS TotalPosts,
    COALESCE(UPS.Questions, 0) AS Questions,
    COALESCE(UPS.Answers, 0) AS Answers,
    COALESCE(UPS.TotalViews, 0) AS TotalViews,
    COALESCE(UPS.TotalScore, 0) AS TotalScore
FROM Users U
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN UserPostStats UPS ON U.Id = UPS.OwnerUserId
WHERE U.Reputation > 100
ORDER BY U.Reputation DESC, BadgeCount DESC
LIMIT 50;
