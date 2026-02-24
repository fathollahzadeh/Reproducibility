WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE t.Count > 0
    GROUP BY t.TagName
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.DisplayName, u.Reputation
    HAVING COUNT(p.Id) > 5
    ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
    ORDER BY p.CreationDate DESC
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore,
    u.DisplayName AS TopUser,
    u.Reputation AS UserReputation,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    p.ViewCount AS RecentPostViews,
    p.Score AS RecentPostScore
FROM TagStatistics ts
JOIN TopUsers u ON ts.PostCount > 1
JOIN RecentPosts p ON ts.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ', ')))
ORDER BY ts.TotalViews DESC, u.Reputation DESC, p.CreationDate DESC;