WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),

UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.TotalViews,
    UPS.TotalScore,
    COALESCE(UBS.TotalBadges, 0) AS TotalBadges,
    COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges
FROM UserPostStats UPS
LEFT JOIN UserBadgeStats UBS ON UPS.UserId = UBS.UserId
ORDER BY UPS.TotalScore DESC, UPS.TotalPosts DESC;