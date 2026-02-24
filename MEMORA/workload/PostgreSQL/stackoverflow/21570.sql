WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) as GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) as SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) as BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActive
    FROM Posts p
    WHERE p.LastActivityDate IS NOT NULL
    GROUP BY p.OwnerUserId
),
QualifiedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) + COALESCE(ub.SilverBadges, 0) + COALESCE(ub.BronzeBadges, 0) AS TotalBadges,
        ps.TotalPosts,
        ps.TotalViews,
        ps.TotalScore,
        ra.LastActive
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN RecentActivity ra ON u.Id = ra.OwnerUserId
    WHERE 
        u.Reputation > 100
        AND (
            (ps.TotalQuestions > 5 AND ps.TotalAnswers > 10)
            OR (ub.GoldBadges > 0)
        )
)
SELECT 
    q.DisplayName,
    q.TotalBadges,
    COALESCE(q.TotalPosts, 0) AS TotalPosts,
    COALESCE(q.TotalViews, 0) AS TotalViews,
    COALESCE(q.TotalScore, 0) AS TotalScore,
    q.LastActive,
    CASE 
        WHEN q.LastActive IS NULL THEN 'Never Active'
        WHEN q.LastActive < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive for over a year'
        ELSE 'Active Recently'
    END AS ActivityStatus
FROM QualifiedUsers q
ORDER BY 
    q.TotalBadges DESC, 
    q.TotalScore DESC,
    q.LastActive DESC;