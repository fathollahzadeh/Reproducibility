
WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) as ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore
    FROM Posts
    GROUP BY OwnerUserId
),
RecentBadgeActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    WHERE Date > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY UserId
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(r.BadgeCount, 0) AS BadgeCount,
        COALESCE(r.BadgeNames, 'No badges') AS BadgeNames,
        ur.ReputationRank
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN RecentBadgeActivity r ON u.Id = r.UserId
    LEFT JOIN UserReputation ur ON u.Id = ur.Id
    WHERE u.Reputation >= 1000
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.AvgScore,
    tu.BadgeCount,
    tu.BadgeNames,
    CASE 
        WHEN tu.AvgScore > 10 THEN 'High Contributor'
        WHEN tu.AvgScore BETWEEN 5 AND 10 THEN 'Moderate Contributor'
        ELSE 'Low Contributor'
    END AS ContributorLevel
FROM TopUsers tu
WHERE tu.TotalPosts > 5
ORDER BY tu.ReputationRank
LIMIT 10;
