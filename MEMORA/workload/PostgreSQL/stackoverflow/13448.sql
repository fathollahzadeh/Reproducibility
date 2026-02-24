
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        Posts.CreationDate,
        COUNT(Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount  
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    GROUP BY 
        Posts.Id, Posts.PostTypeId, Posts.CreationDate
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Badges ON Badges.UserId = Users.Id
    GROUP BY 
        Users.Id, Users.Reputation
)
SELECT 
    p.PostId,
    p.PostTypeId,
    p.CreationDate,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.BadgeCount
FROM 
    PostStats p
JOIN 
    UserStats u ON p.PostTypeId = u.UserId  
ORDER BY 
    p.CreationDate DESC;
