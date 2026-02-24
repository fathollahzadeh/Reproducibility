
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        U.Reputation,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS ClosedCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.Reputation,
    COALESCE(CP.ClosedCount, 0) AS ClosedCount,
    CASE 
        WHEN RP.PostRank = 1 THEN 'Latest Post'
        ELSE 'Previous Post'
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.ViewCount > 100
ORDER BY 
    RP.Score DESC, RP.CreationDate ASC
FETCH FIRST 50 ROWS ONLY;
