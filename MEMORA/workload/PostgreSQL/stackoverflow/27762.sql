
WITH TagStatistics AS (
    SELECT
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    GROUP BY
        TagName
),
UserReputation AS (
    SELECT
        Users.Id,
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY
        Users.Id, Users.DisplayName, Users.Reputation
),
TopTags AS (
    SELECT
        TagName,
        PostCount
    FROM
        TagStatistics
    ORDER BY
        PostCount DESC
    LIMIT 10
)
SELECT
    U.DisplayName,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.Questions,
    U.Answers,
    T.TagName,
    T.PostCount AS TagPostCount
FROM
    UserReputation U
JOIN
    TopTags T ON T.TagName IN (
        SELECT
            TRIM(UNNEST(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><')))
        FROM
            Posts P
        WHERE
            P.OwnerUserId = U.Id
    )
ORDER BY
    U.Reputation DESC, T.PostCount DESC;
