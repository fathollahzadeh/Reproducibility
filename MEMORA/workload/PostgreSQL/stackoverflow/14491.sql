WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
), 
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
MergedData AS (
    SELECT 
        PE.PostId,
        PE.Title,
        PE.CreationDate,
        PE.Score,
        PE.ViewCount,
        PE.AnswerCount,
        PE.CommentCount,
        PE.OwnerDisplayName,
        PE.OwnerReputation,
        PH.EditCount,
        PH.CloseOpenCount
    FROM 
        PostEngagement PE
    LEFT JOIN 
        PostHistoryCounts PH ON PE.PostId = PH.PostId
)
SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    OwnerReputation,
    EditCount,
    CloseOpenCount
FROM 
    MergedData
ORDER BY 
    ViewCount DESC
LIMIT 100;