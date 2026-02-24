WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
           COUNT(c.Id) AS CommentCount,
           AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
RecentPostHistory AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.UserId,
           ph.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT b.UserId,
           STRING_AGG(b.Name, ', ') AS BadgeNames,
           COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT rp.PostId,
       rp.Title,
       rp.Score,
       rp.ViewCount,
       rp.Rank,
       rp.CommentCount,
       COALESCE(up.BadgeNames, 'No Badges') AS UserBadges,
       COALESCE(up.BadgeCount, 0) AS TotalBadges,
       ph.PostHistoryTypeId AS RecentHistoryTypeId,
       ph.CreationDate AS RecentHistoryDate
FROM RankedPosts rp
LEFT JOIN RecentPostHistory ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
LEFT JOIN Users u ON rp.PostId = u.Id
LEFT JOIN UserBadges up ON u.Id = up.UserId
WHERE rp.Rank <= 10
  AND (CASE WHEN rp.CommentCount > 5 THEN TRUE ELSE FALSE END) 
ORDER BY rp.Score DESC, rp.ViewCount DESC;