WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        AnswerCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.ViewCount,
    TP.AnswerCount,
    TP.Score,
    COUNT(C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    TopPosts TP
LEFT JOIN 
    Comments C ON TP.PostId = C.PostId
LEFT JOIN 
    Votes V ON TP.PostId = V.PostId
GROUP BY 
    TP.PostId, TP.Title, TP.OwnerDisplayName, TP.CreationDate, TP.ViewCount, TP.AnswerCount, TP.Score
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;