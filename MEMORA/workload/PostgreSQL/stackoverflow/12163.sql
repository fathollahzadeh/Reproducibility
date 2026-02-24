WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),

UserBadgeStats AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),

CombinedStats AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalViews,
        ups.TotalScore,
        ubs.TotalBadges,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges
    FROM
        UserPostStats ups
    LEFT JOIN
        UserBadgeStats ubs ON ups.UserId = ubs.UserId
)

SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    COALESCE(TotalBadges, 0) AS TotalBadges,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges
FROM
    CombinedStats
ORDER BY
    TotalScore DESC, TotalPosts DESC;