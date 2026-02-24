
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT
        UNNEST(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts p
    WHERE p.PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT TagName, TagCount,
           ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM PopularTags
    WHERE TagCount > 5
)
SELECT 
    ua.DisplayName,
    ua.TotalViews,
    ua.TotalComments,
    tt.TagName,
    tt.TagCount,
    CASE 
        WHEN ua.TotalPosts > 0 THEN (CAST(ua.TotalViews AS decimal) / ua.TotalPosts) 
        ELSE NULL 
    END AS AvgViewsPerPost
FROM UserActivity ua
LEFT JOIN TopTags tt ON ua.UserId IN (
    SELECT DISTINCT p.OwnerUserId
    FROM Posts p
    WHERE p.Tags IS NOT NULL AND p.Tags LIKE '%' || tt.TagName || '%'
)
WHERE ua.Rank <= 10
ORDER BY ua.TotalViews DESC, tt.TagCount DESC;
