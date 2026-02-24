WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    CommentCount,
    AnswerCount,
    VoteCount
FROM 
    PostDetails
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;