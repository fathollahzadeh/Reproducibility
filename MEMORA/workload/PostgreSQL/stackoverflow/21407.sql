WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
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
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.BadgeCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalViews,
        ps.AvgScore
    FROM Users u
    JOIN UserBadgeStats us ON u.Id = us.UserId
    JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        ue.*,
        ROW_NUMBER() OVER (ORDER BY ue.TotalPosts DESC, ue.TotalViews DESC) AS Rank
    FROM UserEngagement ue
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    COALESCE(tu.TotalAnswers, 0) AS TotalAnswers,
    tu.TotalViews,
    tu.AvgScore,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    CASE 
        WHEN tu.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus,
    CASE 
        WHEN tu.TotalPosts > 100 THEN 'Veteran'
        WHEN tu.TotalPosts BETWEEN 50 AND 100 THEN 'Contributor'
        ELSE 'Novice'
    END AS UserLevel
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.Rank;