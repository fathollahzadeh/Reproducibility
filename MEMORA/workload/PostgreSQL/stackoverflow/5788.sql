WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        COALESCE(C.Count, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.ViewCount,
    RP.Score,
    RP.CommentCount,
    PHT.Name AS PostHistoryType,
    U2.DisplayName AS LastEditedBy,
    RP.Rank
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
LEFT JOIN 
    Users U2 ON PH.UserId = U2.Id
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;