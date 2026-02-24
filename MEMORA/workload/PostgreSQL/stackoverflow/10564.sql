
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(Users.Reputation) AS AvgReputation
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        CASE 
            WHEN Posts.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS Status
    FROM 
        Posts
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.Upvotes,
    u.Downvotes,
    u.AvgReputation,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount AS PostAnswerCount,
    p.CommentCount AS PostCommentCount,
    p.Status
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.PostId 
ORDER BY 
    u.PostCount DESC, 
    u.AvgReputation DESC
LIMIT 100;
