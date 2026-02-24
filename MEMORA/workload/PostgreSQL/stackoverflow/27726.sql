WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.CommentId) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
            C.PostId, 
            C.Id AS CommentId
         FROM 
            Comments C) C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),

TopQuestions AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.CommentCount,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.ExcerptPostId = RP.PostId) AS Tags
    FROM 
        RankedPosts RP
    WHERE 
        RP.RN = 1
    ORDER BY 
        RP.Score DESC, RP.ViewCount DESC
    LIMIT 10
)

SELECT 
    TQ.PostId,
    TQ.Title,
    TQ.Body,
    TQ.CreationDate,
    TQ.Score,
    TQ.ViewCount,
    TQ.OwnerDisplayName,
    TQ.CommentCount,
    TQ.Tags
FROM 
    TopQuestions TQ;