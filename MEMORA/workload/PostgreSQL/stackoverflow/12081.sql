
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Votes.Id) AS VoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(Posts.ViewCount) AS TotalViews
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
)
SELECT 
    PostStats.PostId,
    PostStats.Title,
    PostStats.CreationDate,
    PostStats.CommentCount,
    PostStats.VoteCount,
    PostStats.UpVotes,
    PostStats.DownVotes,
    UserStats.UserId,
    UserStats.DisplayName,
    UserStats.BadgeCount,
    UserStats.TotalViews
FROM 
    PostStats
JOIN 
    Posts ON PostStats.PostId = Posts.Id
JOIN 
    Users ON Posts.OwnerUserId = Users.Id
JOIN 
    UserStats ON Users.Id = UserStats.UserId
ORDER BY 
    PostStats.CreationDate DESC
LIMIT 100;
