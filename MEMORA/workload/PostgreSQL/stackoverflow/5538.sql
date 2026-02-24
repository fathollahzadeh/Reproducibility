
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.UpvoteCount,
    TU.DownvoteCount,
    T.Name AS BadgeName,
    ROW_NUMBER() OVER (PARTITION BY TU.UserId ORDER BY B.Date DESC) AS BadgeRank
FROM TopUsers TU
LEFT JOIN Badges B ON TU.UserId = B.UserId
LEFT JOIN PostHistoryTypes T ON B.Class = T.Id
WHERE TU.ReputationRank <= 10
  AND B.Date >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
ORDER BY TU.Reputation DESC, BadgeRank;
