WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
           COUNT(c.Id) AS CommentCount,
           COUNT(DISTINCT v.UserId) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT ph.PostId, 
           COUNT(ph.Id) AS CloseCount,
           STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes ctr ON ctr.Id::text = ph.Comment AND ph.PostHistoryTypeId = 10
    WHERE ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY ph.PostId
),
MaxScore AS (
    SELECT MAX(Score) AS MaxScore
    FROM Posts
)

SELECT rp.PostId,
       rp.Title,
       rp.Score,
       rp.RankScore,
       COALESCE(cp.CloseCount, 0) AS CloseCount,
       COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
       CASE
           WHEN rp.Score < (SELECT MaxScore FROM MaxScore) THEN 'Below Top Score'
           ELSE 'Top Score'
       END AS ScoreCategory,
       CASE 
           WHEN rp.CommentCount > 10 THEN 'Highly Commented'
           WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Commented'
           ELSE 'Few Comments'
       END AS CommentCategory,
       CASE 
           WHEN rp.VoteCount IS NULL THEN 'No Votes'
           WHEN rp.VoteCount <= 5 THEN 'Few Votes'
           ELSE 'Many Votes'
       END AS VoteCategory,
       CASE 
         WHEN (SELECT COUNT(*) FROM Posts p WHERE p.ViewCount IS NULL) > 0 THEN 'Some Posts Unviewed'
         ELSE 'All Posts Viewed'
       END AS ViewStatus
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON cp.PostId = rp.PostId
WHERE rp.RankScore <= 5
ORDER BY rp.RankScore;