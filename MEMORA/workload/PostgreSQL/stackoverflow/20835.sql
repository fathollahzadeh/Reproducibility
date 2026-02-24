
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    CASE 
        WHEN cp.FirstCloseDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ub.BadgeNames
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
JOIN Users u ON u.Id = rp.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE rp.Rank <= 10
  AND (u.Reputation >= 1000 OR COALESCE(ub.BadgeCount, 0) > 1)
  AND (rp.CommentCount > 5 OR rp.Score > 10)
ORDER BY rp.Score DESC, rp.CommentCount DESC;
