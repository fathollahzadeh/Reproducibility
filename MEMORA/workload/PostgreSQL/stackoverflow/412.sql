
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.PostTypeId
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    ch.CloseDate,
    ch.CloseReasons
FROM RankedPosts rp
LEFT JOIN ClosedPostHistory ch ON rp.PostId = ch.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
