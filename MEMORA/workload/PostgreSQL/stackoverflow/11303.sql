
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT Badges.Id) AS TotalBadges,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
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
        Posts.Id AS PostId,
        Posts.PostTypeId,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        Posts.Score,
        Posts.CreationDate,
        Posts.LastActivityDate,
        Posts.OwnerUserId
    FROM 
        Posts
),

CloseReasonStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory 
    WHERE 
        PostHistoryTypeId = 10
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalBadges,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.PostTypeId,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.Score,
    P.CreationDate,
    P.LastActivityDate,
    COALESCE(CR.CloseCount, 0) AS CloseCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    CloseReasonStats CR ON P.PostId = CR.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
