
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate
    FROM Users
    WHERE Reputation > 1000
), PostStats AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           p.CreationDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
), PopularPosts AS (
    SELECT ps.PostId, 
           ps.CommentCount, 
           ps.UpVotes, 
           ps.DownVotes, 
           ps.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY (ps.UpVotes - ps.DownVotes) DESC) AS Rank
    FROM PostStats ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.Id
), LatestPosts AS (
    SELECT PostId, CommentCount, UpVotes, DownVotes, CreationDate
    FROM PopularPosts
    WHERE Rank <= 5
)
SELECT lp.PostId, 
       p.Title, 
       p.Body, 
       lp.CommentCount, 
       lp.UpVotes, 
       lp.DownVotes, 
       u.DisplayName AS OwnerName
FROM LatestPosts lp
JOIN Posts p ON lp.PostId = p.Id
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE ph.PostHistoryTypeId IS NULL
ORDER BY lp.UpVotes DESC, lp.CommentCount DESC;
