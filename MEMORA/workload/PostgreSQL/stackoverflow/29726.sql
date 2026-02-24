WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeMetrics AS (
    SELECT 
        UBC.UserId,
        UBC.DisplayName,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.TotalViews,
        PS.AverageScore,
        UBC.BadgeCount,
        UBC.GoldBadges,
        UBC.SilverBadges,
        UBC.BronzeBadges
    FROM 
        UserBadgeCount UBC
    JOIN 
        PostStatistics PS ON UBC.UserId = PS.OwnerUserId
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    AverageScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    UserPostBadgeMetrics
WHERE 
    TotalPosts > 0
ORDER BY 
    BadgeCount DESC, TotalViews DESC
LIMIT 50;
