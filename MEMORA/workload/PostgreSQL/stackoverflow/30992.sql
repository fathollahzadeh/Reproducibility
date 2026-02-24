
WITH RECURSIVE UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostVoteCounts AS (
    SELECT PostId, 
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
RecentPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.CreationDate,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           COALESCE(bc.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    LEFT JOIN PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
CloseReasons AS (
    SELECT ph.PostId, 
           MAX(ph.CreationDate) AS LastCloseDate, 
           STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT rp.PostId, 
       rp.Title,
       rp.Score, 
       rp.CreationDate, 
       rp.UpVotes, 
       rp.DownVotes, 
       rp.UserBadgeCount,
       cr.LastCloseDate,
       cr.CloseReasonNames,
       CASE 
           WHEN cr.LastCloseDate IS NOT NULL THEN 'Closed'
           ELSE 'Open'
       END AS PostStatus
FROM RecentPosts rp
LEFT JOIN CloseReasons cr ON rp.PostId = cr.PostId
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
