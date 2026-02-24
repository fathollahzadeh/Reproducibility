
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 0 
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
CombinedData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        RP.PostRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)
SELECT 
    CD.OwnerDisplayName,
    CD.Title,
    CD.CreationDate,
    CD.Score,
    CD.ViewCount,
    CD.CloseReason,
    CASE 
        WHEN CD.PostRank = 1 THEN 'Latest Post'
        ELSE 'Other Posts'
    END AS PostStatus
FROM 
    CombinedData CD
WHERE 
    CD.CloseReason IS NULL OR CD.CloseReason = 'Not Closed'
ORDER BY 
    CD.Score DESC,
    CD.CreationDate DESC;
