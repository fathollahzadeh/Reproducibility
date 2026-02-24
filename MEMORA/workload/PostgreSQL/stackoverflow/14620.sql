WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.Score) AS TotalScore,
        SUM(Posts.ViewCount) AS TotalViewCount,
        SUM(Users.UpVotes) AS TotalUpVotes,
        SUM(Users.DownVotes) AS TotalDownVotes
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName
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
        Posts.FavoriteCount,
        PostTypes.Name AS PostType
    FROM Posts
    JOIN PostTypes ON Posts.PostTypeId = PostTypes.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalScore,
    U.TotalViewCount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.PostType
FROM UserStats U
LEFT JOIN PostStats P ON U.UserId = P.PostId
ORDER BY U.TotalScore DESC, U.PostCount DESC;
