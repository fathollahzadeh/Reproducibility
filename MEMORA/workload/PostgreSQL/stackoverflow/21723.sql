
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(NULLIF(P.ClosedDate, P.CreationDate), P.CreationDate) AS EffectiveCloseDate,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId IN (2, 4)) AS Upvotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS Downvotes,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.PostTypeId, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.ClosedDate
),
PostHistoryMetrics AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM PostHistory PH
    GROUP BY PH.PostId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(PM.Score, 0)) AS TotalScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostMetrics PM ON P.Id = PM.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
)
SELECT 
    UR.UserId,
    UR.Reputation,
    UR.ReputationRank,
    PM.Title,
    PM.Score AS PostScore,
    PM.ViewCount,
    PM.CommentCount,
    COALESCE(PTM.CloseCount, 0) AS CloseCount,
    COALESCE(PTM.DeleteUndeleteCount, 0) AS DeleteUndeleteCount,
    PTM.LastChangeDate,
    TU.PostCount,
    TU.TotalScore
FROM UserReputation UR
LEFT JOIN PostMetrics PM ON PM.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UR.UserId)
LEFT JOIN PostHistoryMetrics PTM ON PM.PostId = PTM.PostId
LEFT JOIN TopUsers TU ON TU.UserId = UR.UserId
WHERE UR.ReputationRank <= 50 
AND (UPPER(PM.Title) LIKE '%SQL%' OR PM.ViewCount > 1000)
ORDER BY UR.Reputation DESC;
