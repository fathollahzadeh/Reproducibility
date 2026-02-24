WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT A.Id) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        PT.Name AS PostType
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
),

TopUsers AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.TotalPosts,
        U.TotalAnswers,
        U.TotalComments,
        U.TotalBounties,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM UserStats U
),

TopPosts AS (
    SELECT 
        P.PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM PostStats P
)

SELECT 
    TU.ReputationRank,
    TU.UserId,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalComments,
    TU.TotalBounties,
    TP.ScoreRank,
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount
FROM TopUsers TU
JOIN TopPosts TP ON TU.TotalPosts > 0
WHERE TU.ReputationRank <= 10 AND TP.ScoreRank <= 10
ORDER BY TU.ReputationRank, TP.ScoreRank;