
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND      
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),
PostAnnotations AS (
    SELECT 
        H.PostId,
        STRING_AGG(CASE WHEN H.PostHistoryTypeId = 10 THEN C.Name END, ', ') AS CloseReasons,
        MAX(H.CreationDate) AS LastEdited,
        COUNT(C.Id) AS CommentCount
    FROM 
        PostHistory H
    LEFT JOIN 
        CloseReasonTypes C ON CAST(H.Comment AS TEXT) = CAST(C.Id AS TEXT)  
    GROUP BY 
        H.PostId
)

SELECT 
    T.Title,
    T.Score,
    T.ViewCount,
    T.AnswerCount,
    T.OwnerDisplayName,
    A.CloseReasons,
    A.LastEdited,
    A.CommentCount
FROM 
    TopPosts T
LEFT JOIN 
    PostAnnotations A ON T.PostId = A.PostId
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
