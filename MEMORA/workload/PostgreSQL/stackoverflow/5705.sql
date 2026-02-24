
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(MIN(C.CreationDate), P.CreationDate) AS FirstInteractionDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        FirstInteractionDate
    FROM PostScores
    ORDER BY Score DESC, ViewCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    T.Title,
    T.Score,
    T.ViewCount,
    U.Upvotes,
    U.Downvotes,
    U.CommentCount
FROM UserEngagement U
JOIN TopPosts T ON U.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = T.PostId
)
ORDER BY U.Upvotes DESC, U.CommentCount DESC;
