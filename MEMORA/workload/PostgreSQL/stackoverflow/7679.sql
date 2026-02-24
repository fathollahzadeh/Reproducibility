
WITH UserScores AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
), TopUsers AS (
    SELECT UserId, DisplayName, Upvotes, Downvotes, PostCount, TotalScore,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserScores
    WHERE PostCount > 5
)
SELECT U.DisplayName, 
       U.TotalScore, 
       U.Upvotes, 
       U.Downvotes, 
       U.ScoreRank, 
       COUNT(DISTINCT C.Id) AS CommentCount
FROM TopUsers U
JOIN Comments C ON U.UserId = C.UserId
JOIN PostHistory PH ON C.PostId = PH.PostId
WHERE PH.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND TIMESTAMP '2024-10-01 12:34:56'
GROUP BY U.DisplayName, U.TotalScore, U.Upvotes, U.Downvotes, U.ScoreRank
ORDER BY U.ScoreRank
LIMIT 10;
