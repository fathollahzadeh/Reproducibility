WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentCount,
        AvgUserReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagStatistics
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    AvgUserReputation
FROM TopTags
WHERE TagRank <= 10
ORDER BY TagRank;
