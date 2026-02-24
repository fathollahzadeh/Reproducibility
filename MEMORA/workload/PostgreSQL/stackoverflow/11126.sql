
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        P.LastActivityDate,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, U.DisplayName, P.LastActivityDate
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.LastActivityDate,
    PS.TotalVotes
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC 
LIMIT 100;
