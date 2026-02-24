WITH PostMetrics AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM
        Posts p
    INNER JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pt.Name
)
SELECT
    *,
    (PostCount * 1.0) / NULLIF(SUM(PostCount) OVER (), 0) * 100 AS PercentageOfTotalPosts
FROM
    PostMetrics
ORDER BY
    PostType;