WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.AccountId AS OwnerAccountId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalStats AS (
    SELECT 
        PS.PostId,
        PS.PostTypeId,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        VS.UpVotes,
        VS.DownVotes,
        PS.OwnerReputation,
        BS.TotalBadges
    FROM 
        PostStats PS
    LEFT JOIN 
        VoteStats VS ON PS.PostId = VS.PostId
    LEFT JOIN 
        BadgeStats BS ON PS.OwnerAccountId = BS.UserId
)

SELECT 
    PostId,
    PostTypeId,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    UpVotes,
    DownVotes,
    OwnerReputation,
    TotalBadges
FROM 
    FinalStats
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;