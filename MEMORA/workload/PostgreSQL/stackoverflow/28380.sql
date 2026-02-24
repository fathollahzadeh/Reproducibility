WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
        AVG(CASE WHEN p.PostTypeId = 2 THEN p.Score END) AS AvgAnswerScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.ViewCount ELSE 0 END) AS TotalQuestionViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgQuestionScore,
        AvgAnswerScore,
        TotalQuestionViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY AvgQuestionScore DESC) AS RankByQuestionScore,
        RANK() OVER (ORDER BY AvgAnswerScore DESC) AS RankByAnswerScore
    FROM UserPostStats
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        COALESCE(up.TotalPosts, 0) AS TotalPosts,
        COALESCE(up.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(up.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(up.AvgQuestionScore, 0) AS AvgQuestionScore,
        COALESCE(up.AvgAnswerScore, 0) AS AvgAnswerScore,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN UserPostStats up ON u.Id = up.UserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgQuestionScore,
    AvgAnswerScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM FinalResults
WHERE TotalPosts > 10
ORDER BY AvgQuestionScore DESC, TotalPosts DESC
LIMIT 10;
