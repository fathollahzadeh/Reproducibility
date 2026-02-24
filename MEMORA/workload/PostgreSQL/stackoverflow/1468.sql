
WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UPS.TotalPosts, 0) AS TotalPosts,
        COALESCE(UPS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(UPS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(UBS.TotalBadges, 0) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        UserPostStats UPS ON U.Id = UPS.OwnerUserId
    LEFT JOIN 
        UserBadgeStats UBS ON U.Id = UBS.UserId
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalBadges,
    (TotalPosts * 1.0) / NULLIF(TotalAnswers, 0) AS PostsAnswerRatio
FROM 
    CombinedStats
WHERE 
    (TotalPosts > 5 OR TotalQuestions > 5)
ORDER BY 
    TotalPosts DESC,
    PostsAnswerRatio DESC
FETCH FIRST 10 ROWS ONLY;
