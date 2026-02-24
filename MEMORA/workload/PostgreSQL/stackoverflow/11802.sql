
WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
)

SELECT 
    B.*,
    (SELECT COUNT(*) FROM Posts WHERE ParentId = B.PostId) AS AnswerCount
FROM 
    Benchmark B
ORDER BY 
    B.Score DESC, B.ViewCount DESC
LIMIT 100;
