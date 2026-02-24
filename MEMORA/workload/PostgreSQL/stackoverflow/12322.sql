
WITH user_stats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Users.Id, Users.Reputation
),
top_users AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        BadgeCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM user_stats
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    BadgeCount,
    UpvoteCount,
    DownvoteCount,
    Rank
FROM top_users
WHERE Rank <= 10
ORDER BY Rank;
