
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate AS UserCreationDate,
        U.DisplayName AS UserDisplayName,
        U.Location,
        U.AboutMe,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, 
        P.AnswerCount, P.CommentCount, P.FavoriteCount, 
        U.Id, U.Reputation, U.CreationDate, U.DisplayName, 
        U.Location, U.AboutMe
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.UserId,
    PS.UserDisplayName,
    PS.Reputation,
    PS.UserCreationDate,
    PS.Location,
    PS.AboutMe,
    PS.TotalComments,
    PS.TotalVotes,
    DENSE_RANK() OVER (ORDER BY PS.Score DESC) AS ScoreRank 
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC;
