WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        TopContributors,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM TagCounts
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.TotalScore,
    tt.TopContributors,
    CASE 
        WHEN ScoreRank <= 10 THEN 'Top Score'
        ELSE 'Lower Score'
    END AS ScoreCategory,
    CASE 
        WHEN PostCountRank <= 10 THEN 'Most Active'
        ELSE 'Less Active'
    END AS ActivityCategory
FROM TopTags tt
WHERE tt.TotalViews > 1000
ORDER BY tt.TotalScore DESC, tt.PostCount DESC;
