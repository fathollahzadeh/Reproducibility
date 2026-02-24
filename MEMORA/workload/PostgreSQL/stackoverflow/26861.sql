
WITH TagUsage AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagUsage
    WHERE PostCount > 5 
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        CommentCount,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM UserActivity
    WHERE QuestionCount > 10
)
SELECT
    TU.TagName,
    TU.PostCount,
    PU.DisplayName AS TopUser,
    PU.QuestionCount,
    PU.CommentCount,
    PU.Upvotes,
    PU.Downvotes
FROM TopTags TU
JOIN PopularUsers PU ON PU.QuestionCount > (SELECT AVG(QuestionCount) FROM PopularUsers)
ORDER BY TU.PostCount DESC, PU.QuestionCount DESC;
