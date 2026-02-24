WITH TagStats AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),
ClosedPosts AS (
    SELECT
        th.PostId,
        MAX(th.CreationDate) AS LastClosedDate
    FROM
        PostHistory th
    WHERE
        th.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        th.PostId
),
TagsWithCloseCount AS (
    SELECT
        t.TagName,
        COUNT(cp.PostId) AS ClosedPostCount
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN
        ClosedPosts cp ON p.Id = cp.PostId
    GROUP BY
        t.TagName
)
SELECT
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore,
    ts.AverageScore,
    COALESCE(tc.ClosedPostCount, 0) AS ClosedPostCount,
    ts.Contributors
FROM
    TagStats ts
LEFT JOIN
    TagsWithCloseCount tc ON ts.TagName = tc.TagName
ORDER BY
    ts.TotalScore DESC, ts.TotalViews DESC;