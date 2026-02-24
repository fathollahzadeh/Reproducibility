
WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        U.Reputation AS OwnerReputation,
        PT.Name AS PostType,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, 
        COALESCE(P.AnswerCount, 0), COALESCE(P.CommentCount, 0), 
        COALESCE(P.FavoriteCount, 0), U.Reputation, PT.Name
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerReputation,
    PostType,
    VoteCount
FROM 
    PostEngagement
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 
    100;
