WITH RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount, p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT ur.UserId, ur.Reputation, ur.BadgeCount, rp.PostId, rp.Title, rp.CreationDate
    FROM UserReputation ur
    JOIN RecentPosts rp ON ur.UserId = rp.OwnerUserId
    WHERE ur.Reputation > 1000
    ORDER BY ur.Reputation DESC
    LIMIT 10
)
SELECT tu.UserId, u.DisplayName, tu.Reputation, tu.BadgeCount, tu.Title, tu.CreationDate, 
       p.Tags, v.VoteTypeId, COUNT(v.Id) AS VoteCount
FROM TopUsers tu
JOIN Users u ON tu.UserId = u.Id
LEFT JOIN Posts p ON tu.PostId = p.Id
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY tu.UserId, u.DisplayName, tu.Reputation, tu.BadgeCount, tu.Title, tu.CreationDate, p.Tags, v.VoteTypeId
ORDER BY tu.Reputation DESC, tu.CreationDate DESC;