WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS MostRecentBadgeDate,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        MAX(COALESCE(p.ClosedDate, p.LastActivityDate)) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS ClosedOn,
        COUNT(DISTINCT ph.UserId) FILTER (WHERE ph.PostHistoryTypeId = 10) AS UniqueCloseVoters
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
MergedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        MAX(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS IsQuestion
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id
),
GranularMetrics AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ub.BadgeCount,
        mp.RelatedPostCount,
        mp.IsQuestion,
        ps.LastActivity,
        cp.CloseReasons,
        cp.ClosedOn,
        cp.UniqueCloseVoters
    FROM PostStatistics ps
    JOIN UserBadges ub ON ps.OwnerUserId = ub.UserId
    LEFT JOIN MergedPosts mp ON ps.PostId = mp.PostId
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT 
    gm.PostId,
    gm.CommentCount,
    gm.BadgeCount,
    gm.RelatedPostCount,
    gm.IsQuestion,
    gm.LastActivity,
    gm.CloseReasons,
    gm.ClosedOn,
    gm.UniqueCloseVoters,
    CASE 
        WHEN gm.UniqueCloseVoters > 0 THEN 'Closed by Users'
        ELSE 'Not Closed'
    END AS ClosureStatus,
    CASE 
        WHEN gm.LastActivity < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Stale'
        ELSE 'Active'
    END AS ActivityStatus
FROM GranularMetrics gm
WHERE gm.BadgeCount > 5
ORDER BY gm.PostId DESC;