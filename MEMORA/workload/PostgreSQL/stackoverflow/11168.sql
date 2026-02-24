
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.Reputation AS OwnerReputation,
        P.LastActivityDate,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, 
        U.Reputation, P.LastActivityDate
)

SELECT 
    P.*, 
    PS.CommentCount, 
    PS.UpVotes, 
    PS.DownVotes, 
    PS.OwnerReputation
FROM 
    PostStats PS
JOIN 
    Posts P ON PS.PostId = P.Id
ORDER BY 
    P.ViewCount DESC
LIMIT 100;
