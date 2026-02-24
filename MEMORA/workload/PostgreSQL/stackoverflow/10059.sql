
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
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
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        T.TagName,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Tags T ON POSITION(CONCAT('<', T.TagName, '>') IN P.Tags) > 0
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounty,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.TagName
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY US.Reputation DESC, PS.ViewCount DESC
LIMIT 100;
