WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id, p.ParentId, p.Title, p.OwnerUserId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  
    
    UNION ALL
    
    SELECT p.Id, p.ParentId, p.Title, p.OwnerUserId, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserReputation AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PopularPosts AS (
    SELECT p.Title, p.Score, p.ViewCount, 
           p.OwnerUserId,
           COUNT(c.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
      AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
PostStatistics AS (
    SELECT ph.Id AS PostId, ph.Title, ph.ParentId, 
           COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
           up.ReputationRank,
           pp.CommentCount, pp.Score, pp.ViewCount,
           COALESCE(pp.Upvotes, 0) AS TotalUpvotes,
           COALESCE(pp.Downvotes, 0) AS TotalDownvotes
    FROM PostHierarchy ph
    LEFT JOIN Users u ON ph.OwnerUserId = u.Id
    LEFT JOIN UserReputation up ON u.Id = up.Id
    LEFT JOIN PopularPosts pp ON ph.Id = pp.OwnerUserId
)
SELECT ps.PostId, ps.Title, ps.OwnerDisplayName, ps.ReputationRank,
       ps.CommentCount, ps.Score, ps.ViewCount, 
       (ps.TotalUpvotes - ps.TotalDownvotes) AS NetVotes,
       CASE 
           WHEN ps.Score >= 10 THEN 'High Score'
           WHEN ps.Score BETWEEN 5 AND 9 THEN 'Medium Score'
           ELSE 'Low Score'
       END AS ScoreCategory
FROM PostStatistics ps
WHERE ps.ReputationRank <= 10  
  AND ps.ParentId IS NULL        
ORDER BY ps.Score DESC, ps.CommentCount DESC
LIMIT 20;