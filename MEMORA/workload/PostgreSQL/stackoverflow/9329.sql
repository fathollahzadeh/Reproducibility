WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    WHERE Class = 1 
    GROUP BY UserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, ub.BadgeCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000 AND ub.BadgeCount IS NOT NULL
    ORDER BY u.Reputation DESC
    LIMIT 10
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId, p.CreationDate
    FROM Posts p
    JOIN TopUsers tu ON p.OwnerUserId = tu.Id
    WHERE p.PostTypeId = 1 
    ORDER BY p.Score DESC, p.ViewCount DESC
    LIMIT 5
),
RecentComments AS (
    SELECT c.PostId, COUNT(c.Id) AS CommentCount
    FROM Comments c
    WHERE c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY c.PostId
)
SELECT pp.Title, pp.Score, pp.ViewCount, tu.DisplayName, rc.CommentCount
FROM PopularPosts pp
JOIN TopUsers tu ON pp.OwnerUserId = tu.Id
LEFT JOIN RecentComments rc ON pp.Id = rc.PostId
ORDER BY pp.Score DESC, rc.CommentCount DESC;