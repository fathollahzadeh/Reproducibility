
WITH User_Reputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
Top_Posts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.AnswerCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.Score IS NOT NULL AND P.OwnerUserId IS NOT NULL
),
Post_Statistics AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        COUNT(DISTINCT TP.PostId) AS TotalPosts,
        SUM(COALESCE(TP.Score, 0)) AS TotalScore,
        AVG(COALESCE(TP.AnswerCount, 0)) AS AvgAnswerCount
    FROM User_Reputation UP
    LEFT JOIN Top_Posts TP ON UP.UserId = TP.OwnerUserId
    GROUP BY UP.UserId, UP.DisplayName
),
Closed_Posts AS (
    SELECT 
        H.PostId,
        COUNT(H.Id) AS CloseVoteCount,
        STRING_AGG(CASE WHEN H.Comment IS NOT NULL THEN H.Comment ELSE 'No comment' END, '; ') AS CloseReasons
    FROM PostHistory H
    WHERE H.PostHistoryTypeId = 10
    GROUP BY H.PostId
),
Posts_With_Closed_Info AS (
    SELECT 
        P.PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(CP.CloseVoteCount, 0) AS CloseVoteCount,
        COALESCE(CP.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM Top_Posts P
    LEFT JOIN Closed_Posts CP ON P.PostId = CP.PostId
)
SELECT 
    PS.UserId,
    PS.DisplayName,
    PS.TotalPosts,
    PS.TotalScore,
    PS.AvgAnswerCount,
    P.CloseVoteCount,
    P.CloseReasons
FROM Post_Statistics PS
JOIN Posts_With_Closed_Info P ON PS.UserId = P.OwnerUserId
WHERE PS.TotalPosts > 2 
  AND PS.AvgAnswerCount > 1 
  AND P.CloseVoteCount > 0
ORDER BY PS.TotalScore DESC
LIMIT 50;
