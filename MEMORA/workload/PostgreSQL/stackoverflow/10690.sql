WITH PostMetrics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        COUNT(DISTINCT Badges.Id) AS UserBadgeCount,
        (SELECT COUNT(*) FROM Posts AS Answer WHERE Answer.ParentId = Posts.Id) AS AnswerCount
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    LEFT JOIN 
        Users ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Badges ON Badges.UserId = Users.Id
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Posts.ViewCount
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    UserBadgeCount,
    AnswerCount
FROM 
    PostMetrics
ORDER BY 
    ViewCount DESC,
    Score DESC
LIMIT 100;