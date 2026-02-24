WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionsScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswersScore,
        AVG(U.Reputation) AS AvgReputation
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CM.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments CM ON P.Id = CM.PostId
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.QuestionsCount,
    US.AnswersCount,
    US.QuestionsScore,
    US.AnswersScore,
    US.AvgReputation,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.CommentCount
FROM
    UserStats US
JOIN
    PostDetails PD ON US.UserId = PD.PostId
ORDER BY
    US.AvgReputation DESC, PD.ViewCount DESC
LIMIT 100;