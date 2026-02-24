WITH TagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Tags
    JOIN Posts p ON p.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY Tags.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        PopularPostCount,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
    WHERE PostCount > 1
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' THEN 1 ELSE 0 END) AS RecentActivity,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.BadgeCount,
        ua.RecentActivity,
        ua.TotalScore,
        RANK() OVER (ORDER BY ua.RecentActivity DESC, ua.TotalScore DESC, ua.BadgeCount DESC) AS UserRank
    FROM UserActivity ua
    WHERE ua.RecentActivity > 0
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.PopularPostCount,
    tt.AverageScore,
    au.UserId,
    au.BadgeCount,
    au.RecentActivity,
    au.TotalScore,
    au.UserRank
FROM TopTags tt
JOIN ActiveUsers au ON tt.PostCount > 5 
WHERE tt.TagRank <= 10 
ORDER BY tt.PostCount DESC, au.RecentActivity DESC;