
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(P.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        P.OwnerUserId
    FROM Posts P
)
SELECT 
    US.UserId,
    US.Reputation,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.TotalPosts,
    US.TotalComments,
    US.AvgPostScore,
    P.Title AS PostTitle,
    P.ViewCount,
    P.Score AS PostScore,
    P.AnswerCount,
    P.CommentCount,
    P.HasAcceptedAnswer,
    US.LastPostDate
FROM UserStats US
JOIN PostStats P ON US.UserId = P.OwnerUserId
ORDER BY US.Reputation DESC, P.Score DESC
LIMIT 100;
