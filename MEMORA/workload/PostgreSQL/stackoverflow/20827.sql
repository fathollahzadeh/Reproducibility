
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        CASE 
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreType,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                             WHEN p.Score > 0 THEN 'Positive'
                                             WHEN p.Score < 0 THEN 'Negative'
                                             ELSE 'Neutral'
                                         END 
                           ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS Comments,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.ScoreType,
        COALESCE(vs.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(vs.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(pjd.Comments, 'No Comments') AS Comments,
        CASE 
            WHEN pjd.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM RankedPosts rp
    LEFT JOIN VoteStats vs ON rp.Id = vs.PostId
    LEFT JOIN PostHistoryDetails pjd ON rp.Id = pjd.PostId
    WHERE rp.rn <= 10
)
SELECT 
    f.Id, 
    f.Title, 
    f.ViewCount, 
    f.Score, 
    f.ScoreType, 
    f.UpVoteCount, 
    f.DownVoteCount,
    f.Comments,
    f.PostStatus,
    CASE 
        WHEN f.Score IS NULL THEN 'No Score' 
        ELSE NULL 
    END AS ScoreStatus,
    SUM(COALESCE(CASE WHEN f.ScoreType = 'Positive' THEN 1 ELSE 0 END, 0)) OVER () AS TotalPositivePosts,
    SUM(COALESCE(CASE WHEN f.ScoreType = 'Negative' THEN 1 ELSE 0 END, 0)) OVER () AS TotalNegativePosts
FROM FinalResults f
WHERE f.ViewCount > 100
ORDER BY f.ViewCount DESC
LIMIT 20;
