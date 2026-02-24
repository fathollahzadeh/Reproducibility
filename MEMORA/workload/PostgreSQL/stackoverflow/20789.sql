
WITH UserBadges AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
),
ClosedPostHistory AS (
    SELECT
        ph.UserId,
        COUNT(*) AS CloseVotes,
        MIN(ph.CreationDate) AS FirstCloseDate,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.UserId
),
PostStatsWithBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AcceptedAnswers, 0) AS AcceptedAnswers,
        COALESCE(cph.CloseVotes, 0) AS CloseVotes,
        CASE
            WHEN d.LastCloseDate IS NOT NULL AND COALESCE(cph.CloseVotes, 0) > 0
                THEN 'Active Closer'
            ELSE 'Novice'
        END AS CloserStatus
    FROM
        Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ClosedPostHistory cph ON u.Id = cph.UserId
    LEFT JOIN (
        SELECT ph.UserId, MAX(ph.CreationDate) AS LastCloseDate
        FROM PostHistory ph
        WHERE ph.PostHistoryTypeId = 10
        GROUP BY ph.UserId
    ) d ON u.Id = d.UserId
)
SELECT
    ps.UserId,
    ps.DisplayName,
    ps.GoldBadges + ps.SilverBadges + ps.BronzeBadges AS TotalBadges,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AcceptedAnswers,
    ps.CloseVotes,
    ps.CloserStatus,
    CASE
        WHEN ps.TotalPosts > 0 AND ps.CloseVotes > ps.TotalPosts * 0.5 THEN 'High Risk of Closure'
        WHEN ps.TotalViews > 1000 AND ps.AcceptedAnswers = 0 THEN 'Needs Attention'
        ELSE 'Stable User'
    END AS UserRiskLevel
FROM
    PostStatsWithBadges ps
WHERE
    ps.GoldBadges > 0 OR ps.SilverBadges > 0
ORDER BY
    TotalBadges DESC,
    TotalViews DESC;
