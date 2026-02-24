WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS UserReputation,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             STRING_AGG(TagName, ', ') AS TagName 
         FROM 
             PostLinks PL 
         JOIN 
             Tags T ON PL.RelatedPostId = T.Id 
         GROUP BY 
             PostId) T ON P.Id = T.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    UserReputation,
    TagName
FROM 
    PostMetrics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;