WITH RecursivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.ParentId,
        P.ViewCount,
        P.OwnerUserId,
        P.LastActivityDate,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        DENSE_RANK() OVER(ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
FilteredPosts AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Score,
        R.ViewCount,
        U.Reputation,
        U.ReputationRank,
        PHD.EditCount,
        PHD.LastEditDate,
        PHD.HistoryTypes
    FROM 
        RecursivePosts R
    JOIN 
        UserReputation U ON R.OwnerUserId = U.UserId
    LEFT JOIN 
        PostHistoryDetails PHD ON R.PostId = PHD.PostId
    WHERE 
        R.RN = 1 AND 
        (R.Score > 5 OR R.ViewCount > 100)
)
SELECT 
    FP.Title,
    FP.Score,
    FP.ViewCount,
    COALESCE(FP.EditCount, 0) AS EditCount,
    FP.Reputation,
    FP.ReputationRank,
    CASE 
        WHEN FP.Reputation > 1000 THEN 'High Reputation'
        WHEN FP.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    ARRAY_LENGTH(string_to_array(FP.HistoryTypes, ', '), 1) AS HistoryTypeCount
FROM 
    FilteredPosts FP
WHERE 
    FP.EditCount IS NOT NULL OR 
    FP.ReputationRank < 50
ORDER BY 
    FP.Reputation DESC, 
    FP.LastEditDate DESC
LIMIT 100;