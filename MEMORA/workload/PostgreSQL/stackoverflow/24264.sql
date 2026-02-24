WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
PostLinksCount AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS TotalLinks
    FROM PostLinks pl
    GROUP BY pl.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.CommentCount,
        COALESCE(c.ClosedDate, NULL) AS ClosedDate,
        COALESCE(c.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(plc.TotalLinks, 0) AS TotalLinks
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts c ON rp.PostId = c.PostId
    LEFT JOIN PostLinksCount plc ON rp.PostId = plc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.RankScore,
    fr.CommentCount,
    fr.ClosedDate,
    fr.CloseReason,
    fr.TotalLinks,
    (fr.Score + fr.ViewCount) / NULLIF((fr.CommentCount + 1), 0) AS EngagementScore
FROM FinalResults fr
WHERE fr.RankScore <= 5
ORDER BY fr.Score DESC, fr.ViewCount DESC
LIMIT 100;