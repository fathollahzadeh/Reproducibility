WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.AverageScore,
        ps.TotalViews
    FROM UserBadgeStats ub
    LEFT JOIN PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    COALESCE(TotalBadges, 0) AS TotalBadges,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges,
    COALESCE(TotalPosts, 0) AS TotalPosts,
    COALESCE(Questions, 0) AS Questions,
    COALESCE(Answers, 0) AS Answers,
    COALESCE(AverageScore, 0) AS AverageScore,
    COALESCE(TotalViews, 0) AS TotalViews
FROM CombinedStats
ORDER BY TotalPosts DESC, TotalBadges DESC
LIMIT 100;

