
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserActivity
),
PostScoreHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RecentActivityRank,
        P.OwnerUserId
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.CreationDate,
        PS.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY PS.Score DESC) AS ScoreRank
    FROM PostScoreHistory PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE PS.RecentActivityRank <= 5
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation AS UserReputation,
    TP.Title AS TopPostTitle,
    TP.Score AS PostScore,
    TP.CreationDate AS PostCreationDate,
    TP.OwnerDisplayName AS PostOwnerDisplayName
FROM TopUsers TU
INNER JOIN TopPosts TP ON TU.UserId = TP.OwnerUserId
WHERE TU.ReputationRank <= 10  
ORDER BY TU.Reputation DESC, TP.Score DESC;
