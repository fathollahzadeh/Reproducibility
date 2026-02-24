
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN CH.Id IS NOT NULL THEN 1 END) AS CloseVotes,
        AVG(CASE WHEN CH.PostId IS NOT NULL THEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CH.CreationDate)) END) AS AvgCloseDuration
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory CH ON P.Id = CH.PostId AND CH.PostHistoryTypeId = 10
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, 
        U.Id, U.Reputation, U.DisplayName
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    UserId,
    Reputation,
    DisplayName,
    UpVotes,
    DownVotes,
    CloseVotes,
    AvgCloseDuration
FROM 
    PostMetrics
ORDER BY 
    Score DESC
LIMIT 100;
