
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.Reputation
),
PostStats AS (
    SELECT 
        Id AS PostId,
        PostTypeId,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerUserId
    FROM 
        Posts
),
CloseStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpvoteCount,
    P.PostId,
    P.PostTypeId,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    COALESCE(C.CloseCount, 0) AS CloseCount,
    COALESCE(C.ReopenCount, 0) AS ReopenCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    CloseStats C ON P.PostId = C.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
