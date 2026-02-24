
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, U.Reputation, U.DisplayName
)

SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.AnswerCount,
    PM.CommentCount,
    PM.OwnerReputation,
    PM.OwnerDisplayName,
    RANK() OVER (ORDER BY PM.Score DESC) AS PostRank
FROM 
    PostMetrics PM
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
