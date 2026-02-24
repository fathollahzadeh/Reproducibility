WITH TagStats AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags ILIKE CONCAT('%<', t.TagName, '>%' )
    JOIN
        Users u ON u.Id = p.OwnerUserId
    GROUP BY
        t.TagName
),
RankedTags AS (
    SELECT
        TagName,
        PostCount,
        TotalScore,
        AverageViews,
        ActiveUsers,
        RANK() OVER (ORDER BY TotalScore DESC, PostCount DESC) AS ScoreRank
    FROM
        TagStats
),
PopularTags AS (
    SELECT
        TagName,
        PostCount,
        TotalScore,
        AverageViews,
        ActiveUsers
    FROM
        RankedTags
    WHERE
        ScoreRank <= 10
)
SELECT
    pt.TagName,
    pt.PostCount,
    pt.TotalScore,
    pt.AverageViews,
    pt.ActiveUsers,
    COUNT(DISTINCT p.Id) AS RelatedPostsCount,
    COUNT(DISTINCT c.Id) AS CommentsCount
FROM
    PopularTags pt
LEFT JOIN
    Posts p ON p.Tags ILIKE CONCAT('%<', pt.TagName, '>%' )
LEFT JOIN
    Comments c ON c.PostId = p.Id
GROUP BY
    pt.TagName, pt.PostCount, pt.TotalScore, pt.AverageViews, pt.ActiveUsers
ORDER BY
    pt.TotalScore DESC;
