
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ClosedPostReasons AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPosts,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.AvgScore,
    COALESCE(cpr.ClosedPosts, 0) AS ClosedPosts,
    COALESCE(cpr.CloseReasons, 'None') AS CloseReasons,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.HighestBadgeClass, 0) AS HighestBadgeClass
FROM UserReputation ur
LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN ClosedPostReasons cpr ON ur.UserId = cpr.UserId
LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
WHERE 
    ur.ReputationRank <= 1000 
ORDER BY ur.Reputation DESC, ps.TotalPosts DESC;
