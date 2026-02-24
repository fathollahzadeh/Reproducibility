
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Votes.Id) AS TotalVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT Badges.Id) AS TotalBadges
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Badges ON Posts.OwnerUserId = Badges.UserId
    GROUP BY 
        Posts.Id, Posts.PostTypeId
),
UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
)
SELECT 
    u.UserId,
    u.QuestionCount,
    u.AnswerCount,
    p.PostId,
    p.PostTypeId,
    p.TotalComments,
    p.TotalVotes,
    p.UpVotes,
    p.DownVotes,
    p.TotalBadges
FROM 
    UserStatistics u
JOIN 
    PostStatistics p ON u.UserId = p.PostId
ORDER BY 
    u.UserId, p.PostId;
