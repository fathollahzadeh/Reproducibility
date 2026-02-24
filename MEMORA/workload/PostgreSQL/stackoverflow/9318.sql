WITH UserPostStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN Posts.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalPosts,
        u.TotalQuestions,
        u.TotalAnswers,
        u.AcceptedAnswers,
        u.TotalViews,
        u.TotalScore,
        b.GoldBadges,
        b.SilverBadges,
        b.BronzeBadges
    FROM UserPostStats u
    LEFT JOIN UserBadges b ON u.UserId = b.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AcceptedAnswers,
    TotalViews,
    TotalScore,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM CombinedStats
WHERE TotalPosts > 5
ORDER BY TotalScore DESC, TotalViews DESC
LIMIT 10;
