
WITH UserReputation AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT P.Id AS PostId,
           P.OwnerUserId,
           COALESCE(P.Score, 0) AS Score,
           COALESCE(P.ViewCount, 0) AS ViewCount,
           COALESCE(P.AnswerCount, 0) AS AnswerCount,
           COALESCE(P.CommentCount, 0) AS CommentCount,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           P.CreationDate
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.CreationDate
),
TopUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           UR.Reputation,
           PS.UpVotes,
           PS.DownVotes,
           PS.Score,
           PS.ViewCount,
           PS.AnswerCount,
           PS.CommentCount,
           ROW_NUMBER() OVER (PARTITION BY UR.ReputationRank ORDER BY PS.ViewCount DESC) AS UserRank
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.Id
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation >= 1000
)
SELECT T.UserId,
       T.DisplayName,
       T.Reputation,
       T.UpVotes,
       T.DownVotes,
       T.Score,
       T.ViewCount,
       T.AnswerCount,
       T.CommentCount,
       CASE 
           WHEN T.UserRank IS NULL THEN 'Not Applicable'
           ELSE CAST(T.UserRank AS VARCHAR)
       END AS UserRank
FROM TopUsers T
LEFT JOIN CloseReasonTypes CRT ON T.UpVotes > 10
WHERE T.UserRank <= 10 OR CRT.Id IS NOT NULL
ORDER BY T.Reputation DESC, T.ViewCount DESC;
