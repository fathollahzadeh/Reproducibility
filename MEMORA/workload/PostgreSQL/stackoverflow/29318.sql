
WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY
        t.TagName
), 
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        AVG(u.Reputation) OVER () AS AvgUserReputation
    FROM
        Users u
    JOIN
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY
        u.Id, u.Reputation
),
TagUserEngagement AS (
    SELECT
        ts.TagName,
        ROUND(AVG(ur.Reputation), 2) AS AvgUserReputation,
        SUM(ur.PostsCreated) AS TotalPostsByUsers,
        SUM(ur.TotalPostScore) AS TotalScoreByUsers
    FROM
        TagStatistics ts
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', ts.TagName, '>%')
    JOIN
        UserReputation ur ON p.OwnerUserId = ur.UserId
    GROUP BY
        ts.TagName
)
SELECT
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.WikiCount,
    t.AvgViewCount,
    t.AvgScore,
    u.AvgUserReputation,
    u.TotalPostsByUsers,
    u.TotalScoreByUsers
FROM
    TagStatistics t
LEFT JOIN 
    TagUserEngagement u ON t.TagName = u.TagName
ORDER BY
    t.AvgViewCount DESC,
    t.AvgScore DESC;
