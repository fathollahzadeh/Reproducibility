WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers,
        STRING_AGG(DISTINCT u.Location, ', ') AS UserLocations
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    JOIN
        Users u ON u.Id = p.OwnerUserId
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        ActiveUsers,
        UserLocations,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS Rank
    FROM
        TagStatistics
)
SELECT
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalViews,
    t.TotalScore,
    t.ActiveUsers,
    t.UserLocations
FROM
    TopTags t
WHERE
    t.Rank <= 10  
ORDER BY
    t.TotalScore DESC;