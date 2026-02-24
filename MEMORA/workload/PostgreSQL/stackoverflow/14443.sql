WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        LastPostDate
    FROM
        UserPostStats
    ORDER BY
        TotalPosts DESC
    LIMIT 10
)
SELECT
    U.DisplayName,
    U.Reputation,
    T.TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    T.LastPostDate
FROM
    Users U
JOIN
    TopUsers T ON U.Id = T.UserId;