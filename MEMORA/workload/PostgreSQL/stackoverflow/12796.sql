
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount  
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.AnswerCount, P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.UpVoteCount,
    U.DownVoteCount,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.LastCommentDate
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 100;
