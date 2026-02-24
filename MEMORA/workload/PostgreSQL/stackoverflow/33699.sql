
WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(a.Id), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ub.BadgeNames,
    phi.ClosedDate,
    phi.ReopenedDate,
    phi.DeletedDate,
    CASE 
        WHEN phi.ClosedDate IS NOT NULL AND (phi.ReopenedDate IS NULL OR phi.ClosedDate > phi.ReopenedDate) THEN 'Closed'
        WHEN phi.ReopenedDate IS NOT NULL AND phi.DeletedDate IS NULL THEN 'Reopened'
        WHEN phi.DeletedDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.Score DESC), 0) AS OwnerUserRank
FROM RecursivePostStats ps
LEFT JOIN UserBadges ub ON ps.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryInfo phi ON ps.PostId = phi.PostId
WHERE ps.Score > 0
ORDER BY ps.Score DESC, ps.AnswerCount DESC;
