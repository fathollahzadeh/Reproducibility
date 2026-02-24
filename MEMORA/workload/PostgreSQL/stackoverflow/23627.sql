
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC NULLS LAST) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND P.ViewCount > 0
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE WHEN PH.Comment IS NOT NULL THEN PH.Comment ELSE 'No Comment' END, '; ') AS ClosingComments,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
ValidCloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CASE WHEN CR.Name IS NOT NULL THEN CR.Name ELSE 'Unknown Reason' END, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    LEFT JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INTEGER) = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.Score AS PostScore,
    RP.ViewCount,
    RP.PostTypeId,
    COALESCE(CPH.CloseCount, 0) AS TotalClose,
    COALESCE(VCR.CloseReasons, 'No reasons provided') AS ClosureReasons,
    RP.PostRank
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostHistory CPH ON RP.PostId = CPH.PostId
LEFT JOIN 
    ValidCloseReasons VCR ON RP.PostId = VCR.PostId
WHERE 
    (RP.PostTypeId = 1 AND RP.Score >= 10) 
    OR (RP.PostTypeId = 2 AND RP.ViewCount >= 100) 
ORDER BY 
    RP.CreationDate DESC
LIMIT 100;
