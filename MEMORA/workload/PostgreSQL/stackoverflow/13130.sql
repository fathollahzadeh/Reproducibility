
WITH UserCounts AS (
    SELECT
        Users.Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.Score) AS TotalScore,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Users.Id
),
BadgeCounts AS (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT
        PostTypes.Name AS PostTypeName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM Posts
    JOIN PostTypes ON Posts.PostTypeId = PostTypes.Id
    GROUP BY PostTypes.Name
)

SELECT
    U.UserId,
    U.PostCount,
    U.TotalScore,
    U.UpVotes,
    U.DownVotes,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    P.PostTypeName,
    P.TotalPosts,
    P.TotalViews,
    P.AverageScore
FROM UserCounts U
LEFT JOIN BadgeCounts B ON U.UserId = B.UserId
LEFT JOIN PostStatistics P ON P.TotalPosts > 0
ORDER BY U.TotalScore DESC, U.PostCount DESC;
