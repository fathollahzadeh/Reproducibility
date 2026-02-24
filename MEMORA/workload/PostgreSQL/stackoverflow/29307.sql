
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.CreationDate >= '2022-01-01'
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Score,
        R.CreationDate,
        R.ViewCount,
        R.OwnerDisplayName,
        R.CommentCount
    FROM 
        RankedPosts R
    WHERE 
        R.Rank <= 5
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.CommentCount,
    PH.PostHistoryTypeId,
    PHT.Name AS PostHistoryTypeName,
    PH.CreationDate AS HistoryCreationDate
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    PH.CreationDate IS NOT NULL
ORDER BY 
    TP.Score DESC;
