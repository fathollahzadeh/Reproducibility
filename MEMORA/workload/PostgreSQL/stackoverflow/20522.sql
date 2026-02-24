
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RepRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY p.Id, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Class = 1 
    GROUP BY b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(bs.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(bs.BadgeNames, 'No Gold Badges') AS GoldBadgeNames,
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    cp.CloseCount,
    cp.LastClosedDate
FROM UserReputation u
LEFT JOIN BadgeSummary bs ON u.UserId = bs.UserId
LEFT JOIN PostStatistics ps ON ps.UpVotes > 10 OR ps.DownVotes > 10
LEFT JOIN ClosedPosts cp ON cp.PostId = ps.PostId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
  AND ps.CommentCount < 5
  AND (cp.CloseCount IS NOT NULL OR ps.CommentCount = 0)
ORDER BY u.Reputation DESC, ps.CommentCount ASC, cp.LastClosedDate DESC
LIMIT 100;
