WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(p.Score), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ra.BadgeCount, 0) AS RecentBadgeCount,
        ra.BadgeNames,
        ua.TotalViews,
        ua.TotalScore,
        ua.TotalPosts
    FROM 
        Users u
    JOIN 
        RecursiveUserActivity ua ON u.Id = ua.UserId
    LEFT JOIN 
        RecentBadges ra ON u.Id = ra.UserId
    WHERE 
        u.Reputation >= 1000
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    tu.RecentBadgeCount,
    tu.BadgeNames,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = tu.Id AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month') AS RecentPostsCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = tu.Id AND c.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month') AS RecentCommentsCount
FROM 
    TopUsers tu
WHERE 
    tu.TotalScore > 0
ORDER BY 
    tu.TotalScore DESC
LIMIT 10;