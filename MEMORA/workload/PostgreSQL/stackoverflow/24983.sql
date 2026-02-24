
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
        AND P.Score > 0
),

CloseReasons AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS integer) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),

TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        CR.CloseCount,
        COALESCE(CR.CloseReason, 'No Close Reasons') AS CloseReason
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CloseReasons CR ON RP.PostId = CR.PostId
    WHERE 
        RP.Rank <= 5
)

SELECT 
    TP.*,
    CASE 
        WHEN TP.CloseCount IS NULL THEN 'Active'
        WHEN TP.CloseCount > 0 THEN 'Closed'
        ELSE 'Unknown Status'
    END AS PostStatus,
    (SELECT COUNT(*) 
     FROM Comments C
     WHERE C.PostId = TP.PostId) AS CommentCount,
    (SELECT COUNT(*) 
     FROM Votes V
     WHERE V.PostId = TP.PostId AND V.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) 
     FROM Votes V
     WHERE V.PostId = TP.PostId AND V.VoteTypeId = 3) AS DownVoteCount
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
