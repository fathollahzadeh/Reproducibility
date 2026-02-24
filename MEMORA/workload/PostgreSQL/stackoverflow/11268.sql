
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.OwnerUserId,
        PT.Name AS PostType
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.AnswerCount,
    PD.CommentCount,
    PD.FavoriteCount,
    PD.PostType
FROM UserReputation U
JOIN PostDetails PD ON U.UserId = PD.OwnerUserId
ORDER BY U.Reputation DESC, PD.CreationDate DESC
LIMIT 100;
