
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    TP.Title, 
    TP.CreationDate, 
    TP.Score, 
    TP.ViewCount, 
    TP.OwnerDisplayName, 
    TP.CommentCount, 
    TP.VoteCount,
    HT.Name AS HistoryType
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
WHERE 
    PH.CreationDate >= TP.CreationDate
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
