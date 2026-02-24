
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        Posts.Score,
        Posts.ViewCount,
        ROUND(AVG(COALESCE(Votes.VoteTypeId, 0)) * 1.0, 2) AS AvgVotes,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount
    FROM Posts
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Badges ON Posts.OwnerUserId = Badges.UserId
    GROUP BY Posts.Id, Posts.PostTypeId, Posts.Score, Posts.ViewCount
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(Posts.Id) AS PostCount,
        SUM(Users.UpVotes) AS TotalUpVotes,
        SUM(Users.DownVotes) AS TotalDownVotes,
        AVG(Users.Reputation) AS AvgReputation
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.Score,
    ps.ViewCount,
    ps.AvgVotes,
    ps.CommentCount,
    us.UserId,
    us.PostCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AvgReputation
FROM PostStats ps
JOIN UserStats us ON ps.PostId = us.UserId
ORDER BY ps.Score DESC, ps.ViewCount DESC;
