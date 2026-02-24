
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes
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
    RP.OwnerName,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    COALESCE(RC.CommentCount, 0) AS CommentCount,
    COALESCE(RC.LastCommentDate, NULL) AS LastCommentDate,
    COALESCE(PHS.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(PHS.HistoryTypes, 'No history') AS PostHistoryTypes
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentComments RC ON RP.PostId = RC.PostId
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE 
    RP.PostRank <= 5 
ORDER BY 
    RP.Score DESC;
