WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadges,
        MAX(u.Reputation) AS HighestReputation
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgScore,
    ur.UserId,
    ur.TotalBadges,
    ur.HighestReputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM TagStats ts
INNER JOIN UserReputation ur ON ur.TotalBadges > 1
LEFT JOIN RecentPosts rp ON rp.RecentRank = 1 AND rp.OwnerUserId = ur.UserId
WHERE ts.AvgScore > 5
ORDER BY ts.TotalViews DESC, ur.HighestReputation DESC
LIMIT 10;