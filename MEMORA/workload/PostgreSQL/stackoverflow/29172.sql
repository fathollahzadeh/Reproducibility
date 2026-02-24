
WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),
ClosedPostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN
        Tags t ON t.TagName IN (SELECT unnest(string_to_array(p.Tags, ', ')))
    WHERE
        pht.Name = 'Post Closed'
    GROUP BY
        p.Id, p.Title, ph.CreationDate, ph.UserDisplayName, ph.Comment
),
CombinedStatistics AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        ts.AnswerCount,
        ts.QuestionCount,
        ts.AvgUserReputation,
        cps.PostId,
        cps.Title,
        cps.ClosedDate,
        cps.ClosedBy,
        cps.CloseReason,
        cps.Tags
    FROM
        TagStatistics ts
    LEFT JOIN
        ClosedPostStatistics cps ON ts.TagName IN (SELECT unnest(string_to_array(cps.Tags, ', ')))
)
SELECT
    TagName,
    PostCount,
    AnswerCount,
    QuestionCount,
    AvgUserReputation,
    COUNT(PostId) FILTER (WHERE PostId IS NOT NULL) AS ClosedPostsCount,
    STRING_AGG(DISTINCT Title, '; ') AS ClosedPostsTitles
FROM
    CombinedStatistics
GROUP BY
    TagName,
    PostCount,
    AnswerCount,
    QuestionCount,
    AvgUserReputation
ORDER BY
    PostCount DESC;
