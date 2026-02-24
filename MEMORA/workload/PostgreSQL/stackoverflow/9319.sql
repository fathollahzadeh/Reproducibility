WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    AND p.PostTypeId = 1  
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
), 
PopularTags AS (
    SELECT TagName, PostCount, AvgViews, AvgScore
    FROM TagStatistics
    WHERE PostCount > 5 
    ORDER BY AvgScore DESC 
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pt.TagName,
    pt.PostCount,
    pt.AvgViews,
    pt.AvgScore
FROM RecentPosts rp
JOIN PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
ORDER BY rp.CreationDate DESC, pt.AvgScore DESC;