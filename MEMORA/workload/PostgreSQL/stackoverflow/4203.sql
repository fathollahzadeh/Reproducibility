
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ur.Reputation,
    COALESCE(ur.TotalBadges, 0) AS BadgeCount,
    cp.UserDisplayName AS CloseBy,
    cp.CreationDate AS CloseDate,
    CASE 
        WHEN cp.UserDisplayName IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM RankedPosts rp
LEFT JOIN UserReputation ur ON rp.PostId = ur.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.CommentCount > 5 
    AND ur.Reputation > 100 
    AND (rp.PostRank = 1 OR rp.Score > 10)
ORDER BY rp.CreationDate DESC
LIMIT 50;
