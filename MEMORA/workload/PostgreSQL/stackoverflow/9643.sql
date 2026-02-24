WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
)
SELECT 
    R.PostId,
    R.Title,
    R.ViewCount,
    R.Score,
    R.OwnerDisplayName,
    PHT.Name AS PostHistoryType,
    COUNT(PH.Id) AS HistoryCount
FROM 
    RankedPosts R
LEFT JOIN 
    PostHistory PH ON R.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    R.Rank <= 10
GROUP BY 
    R.PostId, R.Title, R.ViewCount, R.Score, R.OwnerDisplayName, PHT.Name
ORDER BY 
    R.Score DESC, R.ViewCount DESC, HistoryCount DESC;