WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(PH.EditHistoryCount, 0) AS EditCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(V.DownvoteCount, 0) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditHistoryCount 
        FROM 
            PostHistory 
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
)
SELECT 
    PS.PostId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.EditCount,
    PS.CommentCount,
    PS.UpvoteCount,
    PS.DownvoteCount,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId = U.Id
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;