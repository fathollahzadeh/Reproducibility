WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ParentId,
           1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    UNION ALL
    SELECT p.Id AS PostId,
           p.Title,
           p.ParentId,
           ph.Level + 1 AS Level
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
UserVoteCounts AS (
    SELECT v.UserId,
           COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
           COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
    FROM Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostStatistics AS (
    SELECT p.Id AS PostId,
           p.Title,
           COALESCE(ph.Level, 0) AS PostLevel,
           p.Score,
           p.ViewCount,
           COALESCE(uv.UpVoteCount, 0) AS UpVoteCount,
           COALESCE(uv.DownVoteCount, 0) AS DownVoteCount,
           ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN UserVoteCounts uv ON p.OwnerUserId = uv.UserId
)
SELECT ps.PostId,
       ps.Title,
       ps.PostLevel,
       ps.Score,
       ps.ViewCount,
       ps.UpVoteCount,
       ps.DownVoteCount,
       CASE WHEN ps.UpVoteCount - ps.DownVoteCount > 0 THEN 'Positive' 
            WHEN ps.UpVoteCount - ps.DownVoteCount < 0 THEN 'Negative' 
            ELSE 'Neutral' END AS VoteSentiment
FROM PostStatistics ps
WHERE ps.PostLevel > 0
  AND ps.Score > 10
ORDER BY ps.Rank
FETCH FIRST 10 ROWS ONLY;