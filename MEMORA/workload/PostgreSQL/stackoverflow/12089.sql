
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Score,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id, P.Score, P.OwnerUserId
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        AVG(PS.Score) AS AvgScore,
        AVG(PS.CommentCount) AS AvgCommentsPerPost
    FROM
        Users U
    LEFT JOIN
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.Reputation
)
SELECT
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.AvgScore,
    U.AvgCommentsPerPost
FROM
    Posts P
JOIN
    UserStats U ON U.UserId = P.OwnerUserId
GROUP BY
    U.UserId, U.Reputation, U.PostCount, U.AvgScore, U.AvgCommentsPerPost
ORDER BY
    U.Reputation DESC, U.PostCount DESC;
