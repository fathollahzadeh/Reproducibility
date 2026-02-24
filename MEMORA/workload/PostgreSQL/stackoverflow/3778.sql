WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           COALESCE(uc.UserCount, 0) AS UserCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(DISTINCT UserId) AS UserCount
        FROM Votes
        GROUP BY PostId
    ) uc ON p.Id = uc.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostComments AS (
    SELECT PostId, COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT ph.PostId
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 AND ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
OverallStats AS (
    SELECT p.Id AS PostId, 
           p.Title,
           p.Score,
           COALESCE(pc.CommentCount, 0) AS CommentCount,
           GREATEST(COALESCE(tp.UserCount, 0), 1) AS ActiveUsers
    FROM Posts p
    LEFT JOIN PostComments pc ON p.Id = pc.PostId
    LEFT JOIN TopPosts tp ON p.Id = tp.PostId
)

SELECT ost.PostId, ost.Title, ost.Score, ost.CommentCount, 
       CASE 
           WHEN cp.PostId IS NOT NULL THEN 'Closed' 
           ELSE 'Open' 
       END AS PostStatus,
       ur.Reputation,
       ur.ReputationRank
FROM OverallStats ost
LEFT JOIN ClosedPosts cp ON ost.PostId = cp.PostId
JOIN Users u ON ost.PostId = u.Id
JOIN UserReputation ur ON u.Id = ur.UserId
WHERE ost.Score > 0 
  AND ur.ReputationRank <= 100
ORDER BY ost.Score DESC, ur.Reputation DESC;