WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2023-01-01'  
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 10 THEN 1 END) AS DeleteVotes
    FROM 
        Votes V
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
    PS.FavoriteCount,
    PS.OwnerReputation,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    COALESCE(VS.DeleteVotes, 0) AS DeleteVotes
FROM 
    PostSummary PS
LEFT JOIN 
    VoteSummary VS ON PS.PostId = VS.PostId
ORDER BY 
    PS.Score DESC, PS.CreationDate DESC
LIMIT 100;