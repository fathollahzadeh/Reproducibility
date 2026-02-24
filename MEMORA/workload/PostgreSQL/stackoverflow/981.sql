
WITH UserReputation AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStats AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
ClosedPosts AS (
    SELECT p.Id AS ClosedPostId, 
           ph.UserId, 
           ph.CreationDate AS CloseDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
), 
TopUsers AS (
    SELECT ur.Id, ur.Reputation, ur.ReputationRank 
    FROM UserReputation ur
    WHERE ur.ReputationRank <= 10
)

SELECT u.DisplayName, 
       COUNT(DISTINCT ps.PostId) AS TotalPosts, 
       SUM(COALESCE(ps.Score, 0)) AS TotalScore,
       COUNT(DISTINCT cp.ClosedPostId) AS TotalClosedPosts
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostStats ps ON p.Id = ps.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.ClosedPostId
WHERE u.Reputation > 1000 
  AND (u.Location IS NOT NULL OR u.AboutMe IS NOT NULL)
GROUP BY u.DisplayName
HAVING SUM(COALESCE(ps.ViewCount, 0)) > 50
ORDER BY TotalPosts DESC
LIMIT 5
OFFSET 0;
