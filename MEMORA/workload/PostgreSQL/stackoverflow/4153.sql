
WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, 
           CASE 
               WHEN Reputation >= 10000 THEN 'Expert'
               WHEN Reputation >= 1000 THEN 'Experienced'
               WHEN Reputation >= 100 THEN 'Novice'
               ELSE 'Beginner'
           END AS ReputationTier
    FROM Users
), 
PostStatistics AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.PostTypeId, 
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           COUNT(DISTINCT ph.UserId) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseOpenCount 
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
), 
RankedPosts AS (
    SELECT ps.PostId, 
           ps.OwnerUserId, 
           ps.CommentCount, 
           ps.UpVoteCount, 
           ps.DownVoteCount, 
           ur.ReputationTier,
           RANK() OVER (PARTITION BY ur.ReputationTier ORDER BY ps.UpVoteCount DESC) AS PostRank
    FROM PostStatistics ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.UserId
)
SELECT 
    rp.PostId, 
    rp.CommentCount, 
    rp.UpVoteCount, 
    rp.DownVoteCount, 
    rp.ReputationTier,
    rp.PostRank
FROM RankedPosts rp
WHERE rp.PostRank <= 5 
ORDER BY rp.ReputationTier, rp.PostRank;
