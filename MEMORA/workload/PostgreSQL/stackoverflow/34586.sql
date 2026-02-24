WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),

PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    ph.RevisionCount,
    ph.LastRevisionDate,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post'
        WHEN rp.ScoreRank <= 5 THEN 'High Rank'
        ELSE 'Normal Rank'
    END AS RankCategory
FROM RankedPosts rp
LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN PostHistories ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 24  
WHERE rp.ViewCount > 100
  AND (rp.Score > 10 OR ph.RevisionCount > 3)
ORDER BY rp.ViewCount DESC, rp.Score DESC
LIMIT 50;