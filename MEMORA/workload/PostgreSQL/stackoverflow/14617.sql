WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE NULL END) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE NULL END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
OverallStatistics AS (
    SELECT 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT U.Id) AS TotalUsers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.BadgeCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    OS.TotalPosts,
    OS.TotalUsers,
    OS.TotalScore,
    OS.TotalViews
FROM UserActivity UA
LEFT JOIN PostStatistics PS ON UA.UserId = (SELECT OwnerUserId FROM Posts WHERE Posts.Id = PS.PostId)
CROSS JOIN OverallStatistics OS
ORDER BY UA.PostCount DESC;