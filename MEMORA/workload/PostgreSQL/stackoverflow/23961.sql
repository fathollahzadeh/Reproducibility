
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(COALESCE(NULLIF(EXTRACT(EPOCH FROM (P.LastEditDate - P.CreationDate)), 0), NULL)) AS AvgEditTime,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation IS NOT NULL
      AND U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.UserId AS CloserId,
        COUNT(P.Id) AS ClosedPostCount,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS ClosureReasons
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.UserId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.Upvotes,
    US.Downvotes,
    US.AvgEditTime,
    COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(CP.ClosureReasons, 'No closures') AS ClosureReasons
FROM UserStats US
LEFT JOIN ClosedPosts CP ON US.UserId = CP.CloserId
WHERE US.Rank <= 10
ORDER BY US.Reputation DESC
