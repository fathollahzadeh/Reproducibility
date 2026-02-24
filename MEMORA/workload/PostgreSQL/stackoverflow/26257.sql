WITH UserBadges AS (
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
PostAnalysis AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY
        P.OwnerUserId
),
UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PA.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PA.AverageScore, 0) AS AverageScore,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostAnalysis PA ON U.Id = PA.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AverageScore,
    TotalViews,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    UserPostMetrics
ORDER BY 
    TotalPosts DESC,
    BadgeCount DESC
LIMIT 100;
