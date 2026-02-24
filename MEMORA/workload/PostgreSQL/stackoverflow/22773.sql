
WITH RecursivePostStats AS (
    SELECT p.Id AS PostId,
           p.PostTypeId,
           p.AcceptedAnswerId,
           COALESCE(p.ViewCount, 0) AS ViewCount,
           COALESCE(COUNT(c.Id), 0) AS CommentCount,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
           MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosed,
           MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS LastDeleted
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)  
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id
    WHERE p.CreationDate < TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY p.Id, p.PostTypeId, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT ps.PostId,
           ps.PostTypeId,
           ps.ViewCount,
           ps.CommentCount,
           ps.TotalBounty,
           ps.LastClosed,
           ps.LastDeleted,
           CASE
               WHEN ps.LastClosed IS NOT NULL AND ps.LastDeleted IS NULL THEN 'Closed'
               WHEN ps.LastDeleted IS NOT NULL THEN 'Deleted'
               ELSE 'Active'
           END AS Status
    FROM RecursivePostStats ps
    WHERE ps.ViewCount > (
        SELECT AVG(ViewCount)
        FROM RecursivePostStats
    ) * 0.5  
),
RankedPosts AS (
    SELECT fp.*,
           RANK() OVER (PARTITION BY Status ORDER BY ViewCount DESC) AS ViewRank
    FROM FilteredPosts fp
)
SELECT rp.PostId,
       rp.ViewCount,
       rp.CommentCount,
       rp.TotalBounty,
       rp.Status,
       rp.ViewRank,
       CASE
           WHEN rp.Status = 'Active' THEN 'Congrats!'
           WHEN rp.Status = 'Closed' THEN 'Review Needed'
           ELSE 'Archived'
       END AS ReviewStatus,
       COALESCE(
           (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
            FROM Posts p
            JOIN Tags t ON t.ExcerptPostId = p.Id
            WHERE p.Id = rp.PostId
           ), 'No Tags') AS AssociatedTags
FROM RankedPosts rp
WHERE rp.ViewRank <= 10
ORDER BY rp.Status DESC, rp.ViewRank;
