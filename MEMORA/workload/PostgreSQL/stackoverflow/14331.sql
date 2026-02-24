
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        U.Reputation,
        U.CreationDate AS UserCreationDate,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, 
        P.Title, 
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate AS PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.UserId,
    PS.UserDisplayName,
    PS.Reputation,
    PS.UserCreationDate,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    PS.VoteCount
FROM 
    PostStats PS
LEFT JOIN 
    BadgeStats BS ON PS.UserId = BS.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
