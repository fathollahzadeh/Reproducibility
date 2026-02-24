
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Tags,
        COALESCE(PH.UserDisplayName, 'N/A') AS LastEditedBy,
        P.LastEditDate,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.LastEditorUserId = PH.UserId AND P.Id = PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.Tags,
    P.LastEditedBy,
    P.LastEditDate
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 100;
