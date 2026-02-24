WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.Reputation, U.CreationDate
),

TopUsers AS (
    SELECT
        UserId,
        Reputation,
        PostCount,
        QuestionsCount,
        AnswersCount,
        UpVotesCount,
        DownVotesCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM
        UserStats
)

SELECT
    UserId,
    Reputation,
    PostCount,
    QuestionsCount,
    AnswersCount,
    UpVotesCount,
    DownVotesCount,
    Rank
FROM
    TopUsers
WHERE
    Rank <= 10;