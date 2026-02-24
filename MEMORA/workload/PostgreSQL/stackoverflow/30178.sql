
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS TotalClosedPosts,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN p.Score < 0 THEN p.Score ELSE 0 END) AS NegativeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserPerformance AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalClosedPosts,
        ups.PositiveScore,
        ups.NegativeScore,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
    FROM UserPostStats ups
    LEFT JOIN BadgesSummary bs ON ups.UserId = bs.UserId
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, PositiveScore DESC) AS RankByPosts,
        ROW_NUMBER() OVER (PARTITION BY (CASE WHEN TotalQuestions > 0 THEN 1 ELSE 0 END) ORDER BY TotalAnswers DESC) AS RowNumByQuestions
    FROM UserPerformance
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalClosedPosts,
    u.PositiveScore,
    u.NegativeScore,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.RankByPosts,
    u.RowNumByQuestions
FROM RankedUsers u
WHERE 
    u.TotalPosts > 50 
    AND u.GoldBadges > 0
    AND (u.NegativeScore IS NULL OR u.NegativeScore BETWEEN -50 AND -1)
ORDER BY u.RankByPosts, u.DisplayName;
