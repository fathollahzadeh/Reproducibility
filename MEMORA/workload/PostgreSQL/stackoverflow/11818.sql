
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VotesReceived,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
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
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        PT.Name AS PostTypeName
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS Rank
    FROM PostStatistics
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.VotesReceived,
    U.BadgesCount,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.CommentCount,
    TP.FavoriteCount
FROM UserStatistics U
JOIN TopPosts TP ON U.UserId = TP.PostId
WHERE TP.Rank <= 10
ORDER BY U.VotesReceived DESC, U.PostCount DESC;
