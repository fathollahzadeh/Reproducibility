
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), 

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),

ClosedPostCounts AS (
    SELECT 
        ph.UserId, 
        COUNT(ph.Id) AS ClosedPosts
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId
),

FinalResults AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(cb.ClosedPosts, 0) AS ClosedPosts,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ub.TotalBadges
    FROM UserBadgeCounts ub
    LEFT JOIN PostStats ps ON ub.UserId = ps.OwnerUserId
    LEFT JOIN ClosedPostCounts cb ON ub.UserId = cb.UserId
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    ClosedPosts,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalBadges,
    CASE 
        WHEN TotalPosts > 0 AND GoldBadges > 0 THEN 'Active Contributor with Gold'
        WHEN TotalPosts > 0 AND TotalScore > 100 THEN 'Active Contributor with High Score'
        ELSE 'Various Activities'
    END AS UserActivityLabel
FROM FinalResults
ORDER BY TotalScore DESC, TotalPosts DESC
LIMIT 50;
