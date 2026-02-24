WITH UserVotes AS (
    SELECT UserId, 
           COUNT(*) AS TotalVotes,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
           COALESCE(uv.TotalVotes, 0) AS UserTotalVotes,
           COALESCE(uv.UpVotes, 0) AS UserUpVotes,
           COALESCE(uv.DownVotes, 0) AS UserDownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
)
SELECT ps.PostId,
       ps.Title,
       ps.CreationDate,
       ps.Score,
       ps.ViewCount,
       ps.OwnerDisplayName,
       ps.UserTotalVotes,
       ps.UserUpVotes,
       ps.UserDownVotes
FROM PostStats ps
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 100;