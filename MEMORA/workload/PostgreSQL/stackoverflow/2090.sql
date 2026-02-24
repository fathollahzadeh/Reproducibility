
WITH UserReputation AS (
    SELECT Id, Reputation,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostMetrics AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT ur.Id AS UserId, 
           ur.Reputation, 
           pm.TotalPosts,
           pm.Questions,
           pm.Answers,
           pm.Upvotes,
           pm.Downvotes
    FROM UserReputation ur
    JOIN PostMetrics pm ON ur.Id = pm.OwnerUserId
    WHERE ur.Reputation IS NOT NULL
),
PostHistoryCounts AS (
    SELECT ph.UserId,
           COUNT(ph.Id) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY ph.UserId
),
FinalMetrics AS (
    SELECT tu.UserId,
           tu.Reputation,
           COALESCE(phc.EditCount, 0) AS EditCount,
           tu.TotalPosts,
           tu.Questions,
           tu.Answers,
           tu.Upvotes,
           tu.Downvotes,
           CASE WHEN tu.Reputation > 10000 THEN 'High Rank' ELSE 'Low Rank' END AS ReputationCategory
    FROM TopUsers tu
    LEFT JOIN PostHistoryCounts phc ON tu.UserId = phc.UserId
)
SELECT f.UserId, 
       f.Reputation,
       f.EditCount,
       f.TotalPosts,
       f.Questions,
       f.Answers,
       f.Upvotes,
       f.Downvotes,
       f.ReputationCategory
FROM FinalMetrics f
WHERE f.EditCount > 10
ORDER BY f.Reputation DESC, f.TotalPosts DESC
FETCH FIRST 10 ROWS ONLY;
