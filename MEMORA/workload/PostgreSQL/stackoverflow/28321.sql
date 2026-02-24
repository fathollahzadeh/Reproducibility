
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(AVG(P.ViewCount), 0) AS AverageViewsPerPost,
        COALESCE(AVG(P.Score), 0) AS AverageScorePerPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserActivity AS (
    SELECT 
        PS.UserId,
        PS.UserName,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.TotalViews,
        PS.TotalScore,
        PS.AverageViewsPerPost,
        PS.AverageScorePerPost,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        UserPostStats PS 
    JOIN 
        UserBadges UB ON PS.UserId = UB.UserId
)
SELECT 
    UserId,
    UserName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    AverageViewsPerPost,
    TotalScore,
    AverageScorePerPost,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    UserActivity
WHERE 
    TotalPosts > 50 
ORDER BY 
    TotalScore DESC, 
    TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
