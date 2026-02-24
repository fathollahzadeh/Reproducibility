
WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATE '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, U.Reputation, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, AnswerCount, CommentCount, VoteCount, OwnerReputation, OwnerDisplayName
    FROM 
        PostSummary
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10 
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.VoteCount,
    TP.OwnerReputation,
    TP.OwnerDisplayName
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC;
