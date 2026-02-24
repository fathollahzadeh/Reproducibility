
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
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.Score IS NOT NULL
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
),
PostAnalytics AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
        COALESCE(cp.LastCloseDate, '1970-01-01') AS LastCloseDate,
        COALESCE(cp.CloseReasons, 'No reasons available') AS CloseReasons
    FROM PopularPosts pp
    LEFT JOIN ClosedPostDetails cp ON pp.PostId = cp.PostId
    WHERE pp.Rank <= 10
)
SELECT 
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.CloseVoteCount,
    pa.LastCloseDate,
    pa.CloseReasons,
    CASE 
        WHEN pa.CloseVoteCount > 0 AND pa.CloseVoteCount <= 3 THEN 'Low Closure Activity'
        WHEN pa.CloseVoteCount > 3 AND pa.CloseVoteCount <= 10 THEN 'Moderate Closure Activity'
        WHEN pa.CloseVoteCount > 10 THEN 'High Closure Activity'
        ELSE 'No Closure Activity'
    END AS ClosureActivity
FROM UserBadgeStats ub
JOIN PostAnalytics pa ON ub.UserId = pa.PostId
ORDER BY ub.BadgeCount DESC, pa.Score DESC;
