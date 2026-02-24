WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalViews,
        ua.TotalPosts,
        ua.TotalComments,
        RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS PostRank
    FROM UserActivity ua
),
TopUsers AS (
    SELECT 
        r.UserId,
        r.DisplayName,
        r.TotalViews,
        r.TotalPosts,
        r.TotalComments,
        r.ViewRank,
        r.PostRank
    FROM RecentActivity r
    WHERE r.ViewRank <= 10 OR r.PostRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalPosts,
    tu.TotalComments,
    COALESCE(CONCAT('Rank in Views: ', tu.ViewRank), 'N/A') AS ViewRank,
    COALESCE(CONCAT('Rank in Posts: ', tu.PostRank), 'N/A') AS PostRank,
    COALESCE(b.Name, 'No Badge') AS HighestBadge,
    COUNT(v.Id) AS VoteCount
FROM TopUsers tu
LEFT JOIN Badges b ON tu.UserId = b.UserId AND b.Class = 1  
LEFT JOIN Votes v ON tu.UserId = v.UserId
GROUP BY tu.UserId, tu.DisplayName, tu.TotalViews, tu.TotalPosts, tu.TotalComments, tu.ViewRank, tu.PostRank, b.Name
ORDER BY tu.TotalViews DESC, tu.TotalPosts DESC;