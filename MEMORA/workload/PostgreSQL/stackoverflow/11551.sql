
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, U.DisplayName
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    VS.UpVotes,
    VS.DownVotes,
    VS.AcceptedVotes,
    PS.OwnerDisplayName
FROM 
    PostStats PS
LEFT JOIN 
    VoteStats VS ON PS.PostId = VS.PostId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
