WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.AnswerCount) AS AvgAnswerCount,
        AVG(P.CommentCount) AS AvgCommentCount
    FROM Posts P
    GROUP BY P.OwnerUserId
)

SELECT 
    U.UserId,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AvgAnswerCount, 0) AS AvgAnswerCount,
    COALESCE(PS.AvgCommentCount, 0) AS AvgCommentCount,
    U.BadgeCount
FROM UserStats U
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
ORDER BY U.Reputation DESC;