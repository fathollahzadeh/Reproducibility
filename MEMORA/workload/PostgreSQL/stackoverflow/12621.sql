WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.ClosedDate,
        U.Reputation AS OwnerReputation,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.ClosedDate,
    PS.OwnerReputation,
    COALESCE(VS.Upvotes, 0) AS Upvotes,
    COALESCE(VS.Downvotes, 0) AS Downvotes,
    COALESCE(VS.TotalVotes, 0) AS TotalVotes,
    COALESCE(CS.TotalComments, 0) AS TotalComments
FROM 
    PostStats PS
LEFT JOIN 
    VoteStats VS ON PS.PostId = VS.PostId
LEFT JOIN 
    CommentStats CS ON PS.PostId = CS.PostId
ORDER BY 
    PS.CreationDate DESC;