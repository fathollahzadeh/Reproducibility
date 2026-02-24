WITH RECURSIVE TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RN
    FROM Users u
    WHERE u.Reputation > 1000
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM Badges b
    WHERE b.Class = 1 
    GROUP BY b.UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS ClosedPostCount
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.ClosedDate IS NOT NULL
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.Views,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount
FROM TopUsers tu
LEFT JOIN UserBadges ub ON tu.Id = ub.UserId
LEFT JOIN PostStatistics ps ON tu.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON tu.Id = cp.OwnerUserId
WHERE tu.RN <= 50 
ORDER BY tu.Reputation DESC;