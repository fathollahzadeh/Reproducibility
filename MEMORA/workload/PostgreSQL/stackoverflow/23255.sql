
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.LastAccessDate DESC) AS AccessRank
    FROM Users U
    WHERE U.Reputation > 100
), 
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        P.Score,
        DENSE_RANK() OVER (ORDER BY P.CreationDate DESC) AS CreationRank
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        ARRAY_AGG(DISTINCT PHT.Name) AS HistoryTypes,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT 
    UReputation.DisplayName,
    UReputation.Reputation,
    UReputation.Views,
    UReputation.UpVotes,
    UReputation.DownVotes,
    PS.Title,
    PS.CreationDate,
    PH.HistoryCount,
    COALESCE(PS.CommentCount, 0) AS TotalComments,
    PS.TotalBounty,
    PH.LastEditDate,
    CASE 
        WHEN PS.Score > 0 THEN 'Active' 
        ELSE 'Inactive'
    END AS PostActivity,
    CASE 
        WHEN UReputation.Reputation IS NULL THEN 'No Reputation' 
        ELSE 'Reputed'
    END AS UserReputationStatus
FROM UserReputation UReputation
FULL OUTER JOIN PostStats PS ON UReputation.UserId = PS.OwnerUserId
JOIN PostHistoryAggregates PH ON PS.PostId = PH.PostId
WHERE 
    (UReputation.Reputation IS NOT NULL OR PS.Score > 0)
    AND (PH.HistoryCount > 5 OR PH.HistoryCount IS NULL)
ORDER BY 
    UReputation.Reputation DESC NULLS LAST,
    PS.CreationRank ASC,
    PS.Title;
