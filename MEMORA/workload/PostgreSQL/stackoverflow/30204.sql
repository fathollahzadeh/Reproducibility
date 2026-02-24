
WITH RECURSIVE UserReputationCTE AS (
    SELECT u.Id, u.DisplayName, u.Reputation, 1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
  UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),

PostsWithVoteCount AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate,
           COUNT(v.Id) AS VoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY p.Id, p.Title, p.CreationDate
),

ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate,
           COUNT(*) AS CloseCount,
           STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    INNER JOIN CloseReasonTypes c ON CAST(ph.Comment AS INTEGER) = c.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate
),

TopPosts AS (
    SELECT pw.PostId, 
           pw.Title, 
           pw.CreationDate, 
           pw.VoteCount, 
           pw.UpVotes, 
           pw.DownVotes,
           COALESCE(cp.CloseCount, 0) AS CloseCount,
           COALESCE(cp.CloseReasons, 'No reasons') AS CloseReasons,
           u.DisplayName AS OwnerDisplayName
    FROM PostsWithVoteCount pw
    LEFT JOIN ClosedPosts cp ON pw.PostId = cp.PostId
    INNER JOIN Posts p ON pw.PostId = p.Id
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 5000
)

SELECT tp.*, 
       CASE 
          WHEN tp.VoteCount > 50 THEN 'Hot'
          WHEN tp.VoteCount BETWEEN 20 AND 50 THEN 'Trending'
          ELSE 'New'
       END AS PostStatus
FROM TopPosts tp
ORDER BY tp.VoteCount DESC, tp.CreationDate ASC
LIMIT 10;
