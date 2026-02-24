
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.vote_count, 0)) AS VotesReceived
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS vote_count 
        FROM Votes 
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        P.OwnerUserId
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
)

SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.VotesReceived,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.OwnerName,
    P.OwnerReputation
FROM UserStats U
JOIN PostStats P ON U.UserId = P.OwnerUserId
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 100;
