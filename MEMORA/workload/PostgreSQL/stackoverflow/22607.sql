WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           p.Score,
           p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND (p.Score IS NOT NULL OR p.ViewCount IS NOT NULL)
),
PostVoteSummary AS (
    SELECT v.PostId,
           SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
PostHistorySummary AS (
    SELECT ph.PostId,
           STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
           MAX(ph.CreationDate) AS LastActivityDate,
           COUNT(ph.Id) AS HistoryCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT rp.PostId,
           rp.Title,
           rp.ViewCount,
           rp.Score,
           rp.Rank,
           pvs.UpVotes,
           pvs.DownVotes,
           COALESCE(phs.HistoryTypes, 'No History') AS PostHistory,
           phs.LastActivityDate,
           phs.HistoryCount,
           CASE 
               WHEN rp.Score >= 10 THEN 'Hot'
               WHEN rp.Score BETWEEN 5 AND 9 THEN 'Trending'
               ELSE 'Normal' 
           END AS PostStatus
    FROM RankedPosts rp
    LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.PostId
    LEFT JOIN PostHistorySummary phs ON rp.PostId = phs.PostId
    WHERE rp.Rank <= 5
)
SELECT PostId,
       Title,
       ViewCount,
       Score,
       UpVotes,
       DownVotes,
       PostHistory,
       LastActivityDate,
       HistoryCount,
       PostStatus,
       CASE 
           WHEN LastActivityDate IS NULL THEN 'Old Post'
           WHEN LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Recently Active'
           ELSE 'Dormant' 
       END AS ActivityStatus
FROM FinalResults
ORDER BY PostStatus DESC, Score DESC;