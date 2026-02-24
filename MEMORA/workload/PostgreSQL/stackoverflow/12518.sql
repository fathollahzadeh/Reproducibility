
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        Posts.Score,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Posts.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.ViewCount, Posts.Score
),
UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Users.UpVotes) AS TotalUpVotes,
        SUM(Users.DownVotes) AS TotalDownVotes,
        SUM(Users.Reputation) AS TotalReputation
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
)
SELECT 
    P.PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.CommentCount,
    P.VoteCount,
    P.UpVotes,
    P.DownVotes,
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalReputation
FROM 
    PostStatistics P
JOIN 
    UserStatistics U ON P.PostId = U.UserId
ORDER BY 
    P.ViewCount DESC
LIMIT 100;
