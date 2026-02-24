
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    us.Reputation,
    us.CommentCount,
    us.BadgeCount,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount
FROM RankedPosts rp
JOIN UserScores us ON us.UserId = rp.PostId
LEFT JOIN ClosedPosts cp ON cp.PostId = rp.PostId
WHERE rp.RankByScore <= 10
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
