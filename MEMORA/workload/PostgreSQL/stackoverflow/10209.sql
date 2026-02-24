WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueOwners
    FROM Posts p
    GROUP BY p.PostTypeId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.PostsCount,
    us.TotalViews,
    us.TotalScore,
    ps.PostTypeId,
    ps.TotalPosts,
    ps.AvgScore,
    ps.AvgViews,
    ps.UniqueOwners
FROM UserStats us
JOIN PostStats ps ON us.PostsCount > 0  
ORDER BY us.Reputation DESC, ps.TotalPosts DESC;