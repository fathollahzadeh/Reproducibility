
WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           Reputation, 
           PostCount, 
           AnswerCount, 
           QuestionCount,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
),
RecentPosts AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.CreationDate, 
           P.ViewCount, 
           U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT TU.DisplayName, 
       TU.Reputation, 
       TU.PostCount, 
       TU.AnswerCount, 
       TU.QuestionCount, 
       RP.PostId, 
       RP.Title, 
       RP.CreationDate, 
       RP.ViewCount
FROM TopUsers TU
JOIN RecentPosts RP ON TU.DisplayName = RP.OwnerDisplayName 
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, RP.ViewCount DESC;
