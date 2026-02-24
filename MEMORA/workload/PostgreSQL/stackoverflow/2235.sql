WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS ClosedCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY p.OwnerUserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
    COALESCE(cp.ClosedCount, 0) AS ClosedPosts,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.Questions, 0) AS Questions,
    COALESCE(ps.Answers, 0) AS Answers,
    (tu.Reputation * COALESCE(ps.TotalPosts, 0) * 1.0) / NULLIF(COALESCE(cp.ClosedCount, 0), 0) AS PerformanceScore
FROM TopUsers tu
LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
LEFT JOIN ClosedPosts cp ON tu.UserId = cp.OwnerUserId
LEFT JOIN PostStats ps ON tu.UserId = ps.OwnerUserId
WHERE tu.UserRank <= 50
ORDER BY PerformanceScore DESC;
