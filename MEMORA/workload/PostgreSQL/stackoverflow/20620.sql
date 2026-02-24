WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) as ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId AS CloserId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        r.DisplayName,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAcceptedAnswers,
        ps.AvgViewCount,
        ub.Badges,
        COALESCE(ph.ClosedPostCount, 0) AS ClosedPostCount
    FROM RankedUsers r
    LEFT JOIN PostStats ps ON r.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON r.Id = ub.UserId
    LEFT JOIN (
        SELECT 
            CloserId,
            COUNT(PostId) AS ClosedPostCount
        FROM ClosedPostHistory
        GROUP BY CloserId
    ) ph ON r.Id = ph.CloserId
    WHERE r.ReputationRank <= 100
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAcceptedAnswers,
    tu.AvgViewCount,
    tu.Badges,
    tu.ClosedPostCount
FROM TopUsers tu
WHERE 
    (tu.TotalQuestions > 0 AND tu.TotalAcceptedAnswers * 1.0 / tu.TotalQuestions >= 0.5) OR 
    (tu.Badges IS NOT NULL AND tu.ClosedPostCount > 3)
ORDER BY 
    tu.TotalPosts DESC, 
    tu.TotalQuestions DESC;
