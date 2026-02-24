WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.Reputation, U.DisplayName
), TopUsers AS (
    SELECT UserId, Reputation, DisplayName, PostCount,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
), PopularPosts AS (
    SELECT P.Id AS PostId, P.Title, P.Score, P.ViewCount, U.DisplayName AS OwnerName,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(DISTINCT V.UserId) AS VoteCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
    HAVING COUNT(DISTINCT V.UserId) > 10
), TopPosts AS (
    SELECT PostId, Title, Score, ViewCount, OwnerName, CommentCount, VoteCount,
           ROW_NUMBER() OVER (ORDER BY VoteCount DESC) AS Rank
    FROM PopularPosts
)
SELECT T.UserId, T.Reputation, T.DisplayName, T.PostCount, TP.PostId, TP.Title, TP.Score, 
       TP.ViewCount, TP.OwnerName, TP.CommentCount, TP.VoteCount
FROM TopUsers T
JOIN TopPosts TP ON T.PostCount > 5
WHERE T.Rank <= 10 AND TP.Rank <= 5
ORDER BY T.Reputation DESC, TP.VoteCount DESC;