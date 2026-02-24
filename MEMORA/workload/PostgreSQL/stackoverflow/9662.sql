WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.CommentCount,
    tu.Upvotes,
    tu.Downvotes,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.UserId AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year') AS RecentPostCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.UserId) AS BadgeCount
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.Reputation DESC;