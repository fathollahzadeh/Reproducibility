WITH UserStats AS (
    SELECT COUNT(*) AS TotalUsers
    FROM Users
),
PostStats AS (
    SELECT COUNT(*) AS TotalPosts, AVG(ViewCount) AS AvgViewCount
    FROM Posts
),
CommentStats AS (
    SELECT COUNT(*) AS TotalComments, MAX(CreationDate) AS LastCommentDate
    FROM Comments
)
SELECT 
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT AvgViewCount FROM PostStats) AS AvgViewCount,
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT LastCommentDate FROM CommentStats) AS LastCommentDate
;