WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
      AND p.ViewCount IS NOT NULL
),
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        rn,
        Score,
        ViewCount,
        UpvoteCount,
        DownvoteCount,
        CASE
            WHEN UpvoteCount > DownvoteCount THEN 'Positive'
            WHEN UpvoteCount < DownvoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM RankedPosts
),
ClosedPosts AS (
    SELECT 
        DISTINCT ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.Comment
),
FinalMetrics AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.Sentiment,
        COALESCE(cp.LastClosedDate, '1970-01-01') AS LastClosedDate,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason
    FROM PostMetrics pm
    LEFT JOIN ClosedPosts cp ON pm.PostId = cp.PostId
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    Sentiment,
    LastClosedDate,
    CloseReason
FROM FinalMetrics
WHERE Sentiment = 'Positive' 
  AND Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
  AND LastClosedDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '60 days'
ORDER BY Score DESC
LIMIT 10;