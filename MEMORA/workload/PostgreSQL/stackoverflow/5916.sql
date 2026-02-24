WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        (SELECT COUNT(*) FROM Votes V2 WHERE V2.PostId = P.Id AND V2.VoteTypeId IN (1, 4, 5)) AS FavoriteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, U.DisplayName, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes,
        FavoriteCount,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM 
        PostMetrics
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    TP.FavoriteCount,
    CASE 
        WHEN TP.PostRank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS Category
FROM 
    TopPosts TP
ORDER BY 
    TP.PostRank;