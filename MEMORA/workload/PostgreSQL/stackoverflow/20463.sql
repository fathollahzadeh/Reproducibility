WITH RankedUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
PopularTags AS (
    SELECT 
        t.TagName, 
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM Tags t
    WHERE t.Count > (SELECT AVG(Count) FROM Tags)
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserStats AS (
    SELECT 
        ru.Id AS UserId,
        ru.DisplayName,
        COALESCE(pa.TotalPosts, 0) AS TotalPosts,
        COALESCE(pa.TotalViews, 0) AS TotalViews,
        COALESCE(pa.TotalScore, 0) AS TotalScore
    FROM RankedUsers ru
    LEFT JOIN PostAggregates pa ON ru.Id = pa.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
FinalReport AS (
    SELECT 
        us.UserId, 
        us.DisplayName,
        us.TotalPosts,
        us.TotalViews,
        us.TotalScore,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        CASE 
            WHEN ub.BadgeCount IS NULL THEN 'No Badges' 
            ELSE 'Has Badges' 
        END AS BadgeStatus,
        CASE 
            WHEN us.TotalViews > 1000 THEN 'High Views'
            WHEN us.TotalViews BETWEEN 500 AND 1000 THEN 'Medium Views'
            ELSE 'Low Views'
        END AS ViewCategory
    FROM UserStats us
    LEFT JOIN UserBadges ub ON us.UserId = ub.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.TotalPosts,
    fr.TotalViews,
    fr.BadgeStatus,
    pt.TagName AS PopularTag,
    pt.Count AS TagUsage,
    fr.ViewCategory,
    CASE 
        WHEN fr.HighestBadgeClass = 1 THEN 'Gold Medalist'
        WHEN fr.HighestBadgeClass = 2 THEN 'Silver Star'
        WHEN fr.HighestBadgeClass = 3 THEN 'Bronze Companion'
        ELSE 'No Medal'
    END AS BadgeDescription
FROM FinalReport fr
LEFT JOIN PopularTags pt ON fr.TotalPosts > pt.Count
WHERE fr.TotalScore BETWEEN 100 AND 500
ORDER BY fr.TotalScore DESC, fr.TotalPosts DESC
LIMIT 10;