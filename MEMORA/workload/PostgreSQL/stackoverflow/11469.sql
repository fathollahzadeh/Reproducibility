WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pt.Name
)

SELECT
    *,
    (TotalPosts * 1.0 / NULLIF(SUM(TotalPosts) OVER(), 0)) * 100 AS PercentageOfTotalPosts,
    (PositiveScorePosts * 1.0 / NULLIF(TotalPosts, 0)) * 100 AS PercentageOfPositiveScorePosts
FROM
    PostStats
ORDER BY
    TotalPosts DESC;