WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND P.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostComments AS (
    SELECT 
        PC.PostId,
        COUNT(PC.Id) AS CommentCount
    FROM 
        Comments PC
    GROUP BY 
        PC.PostId
),
PostHistoryAggregated AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    COALESCE(PHA.EditCount, 0) AS TotalEdits,
    PHA.LastEdited
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostHistoryAggregated PHA ON TP.PostId = PHA.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;