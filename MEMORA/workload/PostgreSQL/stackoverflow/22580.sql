WITH UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.UserId, ph.PostId, ph.CreationDate
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COUNT(cp.PostId) AS ClosedPostCount,
        MAX(cp.CloseDate) AS LastClosedDate
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ClosedPosts cp ON u.Id = cp.UserId
    GROUP BY u.Id, u.DisplayName, ub.BadgeCount, ps.PostCount, ps.QuestionCount, ps.TotalScore, ps.TotalViews
)
SELECT
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.PostCount,
    ua.QuestionCount,
    ua.TotalScore,
    ua.TotalViews,
    ua.ClosedPostCount,
    ua.LastClosedDate,
    CASE 
        WHEN ua.BadgeCount >= 10 THEN 'Gold'
        WHEN ua.BadgeCount >= 5 THEN 'Silver'
        ELSE 'Bronze'
    END AS BadgeLevel,
    CASE
        WHEN ua.ClosedPostCount > 0 THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS PostClosureStatus
FROM UserActivity ua
WHERE ua.TotalViews > 1000 OR ua.QuestionCount > 5
ORDER BY ua.TotalScore DESC, ua.TotalViews DESC
LIMIT 100;