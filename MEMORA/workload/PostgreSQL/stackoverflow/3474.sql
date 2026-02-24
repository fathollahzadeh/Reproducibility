
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Score, 
           p.CreationDate, 
           p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id, 
           u.DisplayName, 
           u.Reputation, 
           RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
TopUsers AS (
    SELECT ur.Id, 
           ur.DisplayName, 
           ur.Reputation
    FROM UserReputation ur
    WHERE ur.ReputationRank <= 10
)
SELECT p.Id AS PostId, 
       p.Title, 
       p.Score, 
       p.CreationDate, 
       u.DisplayName AS Author, 
       CASE 
           WHEN p.OwnerUserId IS NULL THEN 'Community User' 
           ELSE u.DisplayName 
       END AS PostOwner,
       COALESCE(c.CommentCount, 0) AS TotalComments,
       nt.Name AS Notification
FROM RankedPosts p
LEFT JOIN TopUsers u ON p.OwnerUserId = u.Id
LEFT JOIN (SELECT P.OwnerUserId, COUNT(*) AS CommentCount 
            FROM Comments C 
            JOIN Posts P ON C.PostId = P.Id 
            WHERE P.PostTypeId = 1 
            GROUP BY P.OwnerUserId) AS c ON p.OwnerUserId = c.OwnerUserId
LEFT JOIN PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
LEFT JOIN CloseReasonTypes nt ON (ph.Comment::jsonb ->> 'closeReasonId')::integer = nt.Id
WHERE p.RecentPostRank = 1
ORDER BY p.Score DESC, p.CreationDate DESC
LIMIT 50;
