
WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount,
           STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COUNT(c.Id) AS CommentCount,
           COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate
),
ClosedPosts AS (
    SELECT ph.PostId, 
           MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
RankedPosts AS (
    SELECT ps.PostId,
           ps.Title, 
           ps.CreationDate,
           ps.UpVotes,
           ps.DownVotes,
           ps.CommentCount,
           ps.RelatedPosts,
           cp.LastClosedDate,
           RANK() OVER (ORDER BY ps.UpVotes DESC) AS RankByVotes
    FROM PostStatistics ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT rp.*, 
       ub.BadgeCount,
       ub.BadgeNames
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.PostId = ub.UserId
WHERE rp.RankByVotes <= 10
ORDER BY rp.UpVotes DESC, rp.CreationDate DESC;
