WITH RECURSIVE UserConnections AS (
    SELECT u.Id, u.Reputation, u.DisplayName, 1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000 
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, uc.Level + 1
    FROM Users u
    JOIN Votes v ON v.UserId = u.Id
    JOIN UserConnections uc ON uc.Id = v.PostId 
    WHERE uc.Level < 3  
),
RecentActivity AS (
    SELECT p.OwnerUserId, COUNT(*) AS PostCount, MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, COALESCE(ra.PostCount, 0) AS RecentPostCount
    FROM Users u
    LEFT JOIN RecentActivity ra ON u.Id = ra.OwnerUserId
    WHERE u.Reputation > 5000 
)
SELECT 
    uc.DisplayName AS UserName,
    uc.Reputation,
    tu.DisplayName AS TopUser,
    tu.RecentPostCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes, 
    COUNT(DISTINCT c.Id) AS CommentCount, 
    STRING_AGG(DISTINCT p.Title, '; ') AS PostTitles 
FROM UserConnections uc
LEFT JOIN Votes v ON v.UserId = uc.Id
LEFT JOIN Comments c ON c.UserId = uc.Id
LEFT JOIN Posts p ON p.OwnerUserId = uc.Id
JOIN TopUsers tu ON uc.Id = tu.Id
WHERE uc.Level > 1
GROUP BY uc.Id, uc.DisplayName, uc.Reputation, tu.DisplayName, tu.RecentPostCount
ORDER BY uc.Reputation DESC, tu.RecentPostCount DESC
LIMIT 10;