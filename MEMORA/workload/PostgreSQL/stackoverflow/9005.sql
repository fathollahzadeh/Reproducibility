
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.VoteCount,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END), 0) AS CloseCount,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END), 0) AS DeleteCount
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
GROUP BY 
    TP.PostId, TP.Title, TP.CreationDate, TP.Score, TP.ViewCount, TP.OwnerDisplayName, TP.CommentCount, TP.VoteCount
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
