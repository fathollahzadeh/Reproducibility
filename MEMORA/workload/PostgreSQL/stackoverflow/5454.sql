
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, Score, ViewCount, CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostMetrics AS (
    SELECT 
        T.Title,
        T.OwnerDisplayName,
        T.Score,
        T.ViewCount,
        T.CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = T.PostId AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = T.PostId AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        TopPosts T
)
SELECT 
    PM.Title,
    PM.OwnerDisplayName,
    PM.Score,
    PM.ViewCount,
    PM.CommentCount,
    PM.UpVotes,
    PM.DownVotes,
    ROUND((PM.UpVotes::decimal / NULLIF((PM.UpVotes + PM.DownVotes), 0)) * 100, 2) AS UpVotePercentage
FROM 
    PostMetrics PM
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;
