WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(badge_count.Count, 0) AS BadgeCount,
        u.Views,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRank
    FROM Users u
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS Count
        FROM Badges
        WHERE Class = 1 
        GROUP BY UserId
    ) badge_count ON u.Id = badge_count.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ps.TotalPosts,
        ps.TotalViews,
        ps.TotalScore,
        COALESCE(ur.Views, 0) + COALESCE(ps.TotalViews, 0) AS CombinedViews
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY CombinedViews DESC) AS ViewRank
    FROM UserPerformance
)
SELECT 
    tuv.UserId,
    tuv.DisplayName,
    tuv.Reputation,
    tuv.BadgeCount,
    tuv.TotalPosts,
    tuv.TotalViews,
    tuv.TotalScore,
    tuv.CombinedViews,
    CASE 
        WHEN tuv.BadgeCount > 5 THEN 'Enthusiast'
        WHEN tuv.BadgeCount BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserTier,
    COALESCE(u2.Location, 'N/A') AS Location
FROM TopUsers tuv
LEFT JOIN Users u2 ON tuv.UserId = u2.Id
WHERE tuv.ViewRank <= 10
ORDER BY tuv.CombinedViews DESC
OFFSET (SELECT COUNT(*) FROM TopUsers) * 0.2
LIMIT 5;