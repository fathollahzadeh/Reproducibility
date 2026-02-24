
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
UserPostInsights AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ru.PostCount,
        ru.QuestionCount,
        ru.AnswerCount,
        ru.UpVotes,
        ru.DownVotes,
        (ru.UpVotes - ru.DownVotes) AS NetVotes,
        t.TagName,
        t.PostCount AS TagPostCount,
        t.QuestionCount AS TagQuestionCount,
        t.AnswerCount AS TagAnswerCount
    FROM RankedUsers ru
    LEFT JOIN TagUsage t ON ru.QuestionCount > 0
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    NetVotes,
    STRING_AGG(TagName || ' (' || TagPostCount || ' Posts, ' || TagQuestionCount || ' Questions, ' || TagAnswerCount || ' Answers)', '; ') AS TagsInfo
FROM UserPostInsights
GROUP BY UserId, DisplayName, PostCount, QuestionCount, AnswerCount, UpVotes, DownVotes, NetVotes
ORDER BY NetVotes DESC
LIMIT 10;
