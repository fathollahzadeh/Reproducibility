
WITH UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS TotalBadges
    FROM 
        Users
),
PostStats AS (
    SELECT 
        Id AS PostId,
        PostTypeId,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        CreationDate,
        LastActivityDate,
        (SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id) AS TotalVotes,
        OwnerUserId  -- Added OwnerUserId to be compatible with the JOIN clause later
    FROM 
        Posts
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
    U.UserId,
    U.Reputation,
    U.Views,
    U.TotalPosts,
    U.TotalBadges,
    P.PostId,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    COALESCE(C.TotalComments, 0) AS TotalComments,
    P.LastActivityDate
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    CommentStats C ON P.PostId = C.PostId
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;
