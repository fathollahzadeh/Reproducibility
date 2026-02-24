WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikiCount,
        SUM(CASE WHEN P.PostTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount,
        AVG(P.Score) AS AverageScore
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.Reputation, U.CreationDate
),
TagStats AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        SUM(P.ViewCount) AS TotalViewCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY
        T.Id, T.TagName
)
SELECT
    U.UserId,
    U.Reputation,
    U.CreationDate,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TagWikiCount,
    U.ClosedPostCount,
    U.AverageScore,
    T.TagId,
    T.TagName,
    T.TotalViewCount,
    T.PostCount AS TagPostCount,
    T.AverageScore AS TagAverageScore
FROM
    UserStats U
JOIN
    TagStats T ON T.PostCount > 0
ORDER BY
    U.PostCount DESC, T.TotalViewCount DESC
LIMIT 100;