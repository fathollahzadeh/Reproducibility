
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AverageScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, PositivePosts, NegativePosts, AverageScore
    FROM 
        UserStats
    WHERE 
        PostRank <= 10
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS AwardDate,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositivePosts,
    tu.NegativePosts,
    tu.AverageScore,
    COALESCE(rb.BadgeName, 'No Recent Badge') AS RecentBadge,
    rb.AwardDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentBadges rb ON tu.UserId = rb.UserId AND rb.BadgeRank = 1
WHERE 
    tu.AverageScore IS NOT NULL
ORDER BY 
    tu.TotalPosts DESC;
