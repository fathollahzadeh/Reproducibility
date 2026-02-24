WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount
),
MostCommentedPosts AS (
    SELECT PostId, 
           COUNT(c.Id) AS TotalComments
    FROM Comments c
    GROUP BY c.PostId
    HAVING COUNT(c.Id) >= (SELECT AVG(CommentCount) FROM RankedPosts)
),
PostVoteCounts AS (
    SELECT p.Id AS PostId,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT p.Id AS PostId,
           MAX(ph.CreationDate) AS LastClosedDate,
           STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    LEFT JOIN CloseReasonTypes ctr ON ctr.Id = CAST(ph.Comment AS INT)
    GROUP BY p.Id
)
SELECT p.Id AS PostId, 
       p.Title, 
       p.CreationDate, 
       pr.RankByViews,
       pv.TotalUpVotes,
       pv.TotalDownVotes,
       cp.LastClosedDate,
       cp.CloseReasons
FROM RankedPosts pr
JOIN Posts p ON pr.PostId = p.Id
LEFT JOIN PostVoteCounts pv ON p.Id = pv.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
WHERE pr.RankByViews <= 10
  AND (cp.LastClosedDate IS NOT NULL AND cp.LastClosedDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR')
  OR (pv.TotalUpVotes - pv.TotalDownVotes) > 10
ORDER BY pr.RankByViews, p.CreationDate DESC
LIMIT 50;