
WITH TagStats AS (
    SELECT
        TRIM(Tags) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    WHERE
        Tags IS NOT NULL
    GROUP BY
        TRIM(Tags)
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagStats
    WHERE
        PostCount > 10 
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON U.Id = C.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY TotalComments DESC, TotalPosts DESC) AS UserRank
    FROM
        UserReputation
    WHERE
        Reputation > 50 
)
SELECT
    T.Tag,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    U.UserId AS TopUserId,
    U.DisplayName AS TopUserDisplayName,
    U.Reputation AS TopUserReputation,
    ROW_NUMBER() OVER (PARTITION BY T.Tag ORDER BY U.TotalComments DESC) AS UserRankInTag
FROM
    TopTags T
JOIN
    UserReputation U ON T.Tag LIKE '%' || U.DisplayName || '%'
WHERE
    U.TotalComments > 5
ORDER BY
    T.Tag, UserRankInTag
LIMIT 50;
