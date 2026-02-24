
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.CommentCount) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
FinalStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalScore,
        UPS.TotalViews,
        UPS.TotalComments,
        BS.GoldBadges,
        BS.SilverBadges,
        BS.BronzeBadges
    FROM UserPostStats UPS
    LEFT JOIN BadgeStats BS ON UPS.UserId = BS.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    TotalComments,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
FROM FinalStats
WHERE TotalPosts > 10
ORDER BY TotalScore DESC, TotalPosts DESC
LIMIT 50;
