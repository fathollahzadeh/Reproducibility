WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        (SELECT
            PostId,
            COUNT(*) AS CommentCount
         FROM
            Comments
         GROUP BY
            PostId) C ON P.Id = C.PostId
    GROUP BY
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        Reputation,
        PostCount,
        TotalScore,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM
        UserStats
)
SELECT
    U.DisplayName,
    U.Reputation,
    T.PostCount,
    T.TotalScore,
    T.TotalComments,
    T.ScoreRank
FROM
    TopUsers T
JOIN
    Users U ON T.UserId = U.Id
WHERE
    T.ScoreRank <= 10
ORDER BY
    T.ScoreRank;