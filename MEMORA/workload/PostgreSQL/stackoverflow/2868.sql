WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate,
           ph.UserId,
           STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.CreationDate, ph.UserId
)
SELECT rp.PostId,
       rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       ur.Reputation,
       ur.BadgeCount,
       cp.CloseReasons
FROM RankedPosts rp
LEFT JOIN UserReputation ur ON ur.UserId = rp.PostId
LEFT JOIN ClosedPosts cp ON cp.PostId = rp.PostId
WHERE rp.Rank <= 5
ORDER BY rp.ViewCount DESC, rp.Score DESC
LIMIT 50;