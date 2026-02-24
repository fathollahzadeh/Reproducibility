
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM
        RankedPosts
    WHERE
        Tags IS NOT NULL
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS TagRank
    FROM
        TagStatistics
    WHERE
        PostCount > 10  
)
SELECT
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AverageScore,
    (SELECT COUNT(*) FROM Posts p WHERE p.Tags LIKE '%' || tt.TagName || '%') AS TotalPostsWithTag,
    (SELECT STRING_AGG(DISTINCT rp.OwnerDisplayName, ', ') FROM RankedPosts rp WHERE rp.Tags LIKE '%' || tt.TagName || '%' AND rp.Rank <= 5) AS TopContributors
FROM
    TopTags tt
WHERE
    tt.TagRank <= 10  
ORDER BY
    tt.TotalViews DESC;
