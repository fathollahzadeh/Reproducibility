WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
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
        AverageScore,
        ActiveUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM
        TagStatistics
)
SELECT
    RankByPosts,
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    AverageScore,
    ActiveUsers
FROM
    TopTags 
WHERE
    RankByPosts <= 10
ORDER BY
    RankByPosts;
