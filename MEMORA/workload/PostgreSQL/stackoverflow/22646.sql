WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActivity,
        COALESCE(ph.ChangeTypeCount, 0) AS HistoryChangeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ChangeTypeCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
    GROUP BY p.Id, ph.ChangeTypeCount
),
PostStats AS (
    SELECT 
        pa.PostId,
        pa.CommentCount,
        pa.LastActivity,
        pv.UpVotes,
        pv.DownVotes,
        ub.BadgeCount,
        (pv.UpVotes - pv.DownVotes) AS ScoreDifference
    FROM PostActivity pa
    JOIN PostVotes pv ON pa.PostId = pv.PostId
    LEFT JOIN UserBadges ub ON pv.UpVotes > 0 AND ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pa.PostId)
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.LastActivity,
    ps.UpVotes,
    ps.DownVotes,
    ps.ScoreDifference,
    CASE 
        WHEN ps.ScoreDifference > 100 THEN 'Highly Active'
        WHEN ps.ScoreDifference BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM PostStats ps
WHERE ps.CommentCount IS NOT NULL
  AND ps.LastActivity >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY ps.ScoreDifference DESC
FETCH FIRST 100 ROWS ONLY;