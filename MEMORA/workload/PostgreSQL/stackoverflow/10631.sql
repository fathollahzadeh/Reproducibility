
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPS.PostCount, 0) AS PostCount,
    COALESCE(UPS.TotalScore, 0) AS TotalScore,
    COALESCE(UPS.TotalViews, 0) AS TotalViews,
    COALESCE(UPS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(UBS.BadgeCount, 0) AS BadgeCount,
    COALESCE(UBS.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(UBS.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(UBS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    Users U
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN 
    UserBadgeStats UBS ON U.Id = UBS.UserId
ORDER BY 
    COALESCE(UPS.TotalScore, 0) DESC
LIMIT 100;
