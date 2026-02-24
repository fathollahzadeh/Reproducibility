
WITH PostEngagement AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.UserId,
           ph.CreationDate AS HistoryDate,
           p.Title,
           r.Name AS HistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes r ON ph.PostHistoryTypeId = r.Id
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
      AND ph.Comment IS NOT NULL
),
RecentEngagements AS (
    SELECT PostId,
           COUNT(*) AS RecentEngagementCount,
           COUNT(CASE WHEN HistoryType LIKE '%Close%' THEN 1 END) AS CloseCount,
           COUNT(CASE WHEN HistoryType LIKE '%Edit%' THEN 1 END) AS EditCount,
           COUNT(CASE WHEN HistoryType LIKE '%Rollback%' THEN 1 END) AS RollbackCount
    FROM PostHistoryDetails
    GROUP BY PostId
)
SELECT  e.Rank,
        e.PostId,
        e.Title,
        e.Score,
        e.ViewCount,
        e.TotalBounties,
        e.CommentCount,
        e.BadgeCount,
        COALESCE(r.RecentEngagementCount, 0) AS RecentEngagementCount,
        COALESCE(r.CloseCount, 0) AS CloseCount,
        COALESCE(r.EditCount, 0) AS EditCount,
        COALESCE(r.RollbackCount, 0) AS RollbackCount
FROM PostEngagement e
LEFT JOIN RecentEngagements r ON e.PostId = r.PostId
WHERE e.Rank <= 10 
ORDER BY e.Score DESC, e.ViewCount DESC;
