
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           p.Score,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
           COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    AND p.PostTypeId = 1
),
UserScores AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL AND vt.Id = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL AND vt.Id = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL AND vt.Id = 10 THEN 1 ELSE 0 END), 0) AS Deletes,
           COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL AND vt.Id = 11 THEN 1 ELSE 0 END), 0) AS Undeletes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT ph.PostId,
           ph.UserId,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.UserId
)
SELECT DISTINCT u.DisplayName,
                p.Title,
                p.ViewCount,
                p.Score,
                p.ScoreRank,
                us.UpVotes,
                us.DownVotes,
                COALESCE(cph.CloseCount, 0) AS CloseCount,
                COALESCE(cph.ReopenCount, 0) AS ReopenCount,
                COALESCE(NULLIF(us.UpVotes, 0) / NULLIF(us.DownVotes, 0), 0) AS VoteRatio
FROM RankedPosts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserScores us ON u.Id = us.UserId
LEFT JOIN ClosedPostHistory cph ON p.PostId = cph.PostId
WHERE u.Reputation > 100
AND (p.Score > 10 OR (p.ViewCount > 1000 AND p.Score > 5))
ORDER BY VoteRatio DESC, p.Score DESC
LIMIT 100;
