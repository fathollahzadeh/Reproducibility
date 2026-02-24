
WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        COUNT(c.Id) AS CommentsCount,
        COALESCE(AVG(u.Reputation), 0) AS AverageUserReputation,
        MAX(p.CreationDate) AS MostRecentPostDate
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        QuestionsCount,
        AnswersCount,
        WikiCount,
        CommentsCount,
        AverageUserReputation,
        MostRecentPostDate,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStatistics
)
SELECT
    TagName,
    PostCount,
    QuestionsCount,
    AnswersCount,
    WikiCount,
    CommentsCount,
    AverageUserReputation,
    MostRecentPostDate
FROM
    TopTags
WHERE
    Rank <= 10
ORDER BY
    AverageUserReputation DESC;
