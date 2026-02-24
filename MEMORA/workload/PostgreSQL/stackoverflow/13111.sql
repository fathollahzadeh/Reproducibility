
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        QuestionCount,
        AnswerCount,
        CommentCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM
        UserActivity
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    QuestionCount,
    AnswerCount,
    CommentCount,
    ScoreRank,
    PostCountRank
FROM
    TopUsers
WHERE
    ScoreRank <= 10 OR PostCountRank <= 10
ORDER BY
    ScoreRank, PostCountRank;
