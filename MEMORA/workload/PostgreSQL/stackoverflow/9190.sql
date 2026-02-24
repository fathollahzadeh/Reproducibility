
WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC, ub.BadgeCount DESC) AS Rank
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    ORDER BY p.ViewCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount,
    pp.Title AS PopularPost,
    pp.ViewCount,
    pp.Score,
    pp.CreationDate
FROM TopUsers tu
JOIN PopularPosts pp ON tu.DisplayName = pp.OwnerDisplayName
ORDER BY tu.Rank, pp.ViewCount DESC;
