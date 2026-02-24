WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.Questions, 0) AS TotalQuestions,
        COALESCE(P.Answers, 0) AS TotalAnswers,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(B.TotalBadges, 0) AS TotalBadges
    FROM Users U
    LEFT JOIN PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN UserBadgeStats B ON U.Id = B.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalBadges,
    RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
FROM UserEngagement
WHERE TotalPosts > 0
ORDER BY TotalScore DESC, TotalPosts DESC
LIMIT 10;
