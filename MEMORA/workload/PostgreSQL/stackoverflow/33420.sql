WITH RECURSIVE UserBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT p.Id AS PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    ub.DisplayName, 
    ub.BadgeCount, 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = pp.Id) AS CommentCount,
    (SELECT STRING_AGG(cht.Name, ', ') 
     FROM PostHistory ph
     JOIN PostHistoryTypes cht ON ph.PostHistoryTypeId = cht.Id
     WHERE ph.PostId = pp.Id) AS ChangeHistory
FROM UserBadges ub
JOIN RecentPosts pp ON ub.UserId = pp.OwnerUserId
LEFT JOIN PostVoteSummary pvs ON pp.Id = pvs.PostId
WHERE pp.RN = 1
ORDER BY ub.BadgeCount DESC, pp.ViewCount DESC
LIMIT 50;