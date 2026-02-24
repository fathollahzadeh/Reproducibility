WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.PostTypeId
),

PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypeNames,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.PostTypeId,
    RP.UpVotes,
    RP.DownVotes,
    COALESCE(PHA.HistoryTypeNames, 'No Actions') AS HistoryTypeNames,
    PHA.CloseReopenCount,
    CASE 
        WHEN (RP.UpVotes - RP.DownVotes) > 0 THEN 'Positive'
        WHEN (RP.UpVotes - RP.DownVotes) = 0 THEN 'Neutral'
        ELSE 'Negative'
    END AS Sentiment,
    cast('2024-10-01 12:34:56' as timestamp) - RP.CreationDate AS TimeSinceCreated
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryAggregates PHA ON RP.PostId = PHA.PostId
WHERE 
    RP.Rank = 1 
    AND RP.PostTypeId IN (1, 2) 
    AND (CASE 
            WHEN PHA.CloseReopenCount > 0 THEN 'Yes'
            ELSE 'No'
          END) = 'No'
ORDER BY 
    RP.CreationDate DESC
LIMIT 10;