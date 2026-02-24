WITH RankBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
PostStats AS (
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
CombinedStats AS (
    SELECT 
        R.UserId,
        R.DisplayName,
        R.TotalBadges,
        R.GoldBadges,
        R.SilverBadges,
        R.BronzeBadges,
        P.TotalPosts,
        P.TotalQuestions,
        P.TotalAnswers,
        P.TotalViews,
        P.AverageScore
    FROM 
        RankBadges R
    LEFT JOIN 
        PostStats P ON R.UserId = P.OwnerUserId
    WHERE 
        R.TotalBadges > 0 OR P.TotalPosts > 0
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    AverageScore
FROM 
    CombinedStats
ORDER BY 
    TotalPosts DESC, TotalBadges DESC
LIMIT 25;
