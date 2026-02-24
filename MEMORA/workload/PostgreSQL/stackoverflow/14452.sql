
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        u.Id, u.Reputation
),

TagStats AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%,', t.TagName, ',%') OR p.Tags LIKE CONCAT(t.TagName, ',%') OR p.Tags LIKE CONCAT('%,', t.TagName) OR p.Tags = t.TagName
    GROUP BY
        t.Id, t.TagName
)

SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.Upvotes,
    u.Downvotes,
    u.CommentCount,
    t.TagId,
    t.TagName,
    t.PostCount AS TagPostCount,
    t.QuestionCount AS TagQuestionCount,
    t.AnswerCount AS TagAnswerCount
FROM
    UserStats u
JOIN
    TagStats t ON u.PostCount > 0
ORDER BY
    u.Reputation DESC, t.PostCount DESC
LIMIT 100;
