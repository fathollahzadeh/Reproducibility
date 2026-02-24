
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(AVG(P.Score), 0) AS AvgScore
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
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.AvgScore,
    COALESCE(UBS.TotalBadges, 0) AS TotalBadges,
    COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(COALESCE(C.Score, 0)) AS TotalCommentScores
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadgeStats UBS ON UPS.UserId = UBS.UserId
LEFT JOIN 
    Comments C ON UPS.UserId = C.UserId
WHERE 
    UPS.TotalPosts > 0
GROUP BY 
    UPS.UserId, UPS.DisplayName, UPS.TotalPosts, UPS.TotalQuestions, UPS.TotalAnswers, UPS.AvgScore, 
    UBS.TotalBadges, UBS.GoldBadges, UBS.SilverBadges, UBS.BronzeBadges
ORDER BY 
    UPS.TotalPosts DESC, UPS.AvgScore DESC
LIMIT 50 OFFSET 0;
