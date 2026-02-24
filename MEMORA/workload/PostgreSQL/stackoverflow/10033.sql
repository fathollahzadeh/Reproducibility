
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COUNT(Votes.Id) AS VoteCount,
        COUNT(Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(1) FROM Posts AS Answers WHERE Answers.ParentId = Posts.Id) AS AnswerCount
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Posts.ViewCount
), 
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
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
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.VoteCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.AnswerCount,
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.TotalViews,
    US.TotalScore
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.PostId = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
