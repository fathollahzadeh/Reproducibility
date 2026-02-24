
WITH UserActivity AS (
    SELECT
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Comments ON Users.Id = Comments.UserId
    LEFT JOIN Votes ON Users.Id = Votes.UserId
    GROUP BY Users.Id, Users.Reputation
),
PostStatistics AS (
    SELECT
        Posts.OwnerUserId,
        COUNT(Posts.Id) AS TotalPosts,
        AVG(Posts.Score) AS AverageScore,
        SUM(Posts.ViewCount) AS TotalViews,
        COUNT(DISTINCT Posts.Id) FILTER (WHERE Posts.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT Posts.Id) FILTER (WHERE Posts.PostTypeId = 2) AS AnswerCount
    FROM Posts
    GROUP BY Posts.OwnerUserId
)
SELECT
    ua.UserId,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.UpVotes,
    ua.DownVotes,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    ps.QuestionCount,
    ps.AnswerCount
FROM UserActivity ua
LEFT JOIN PostStatistics ps ON ua.UserId = ps.OwnerUserId
ORDER BY ua.Reputation DESC, ua.PostCount DESC;
