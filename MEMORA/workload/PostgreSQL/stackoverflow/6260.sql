WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScoreStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT H.UserId) AS EditCount,
        MAX(H.CreationDate) AS LastEditDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory H ON P.Id = H.PostId
    GROUP BY P.Id, P.Title, P.Score
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.CommentCount,
        PS.LastEditDate,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC) AS PostRank
    FROM PostScoreStats PS
    WHERE PS.Score > 0
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT H.Id) AS EditsMade
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN PostHistory H ON U.Id = H.UserId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    UVS.UserId,
    UVS.DisplayName,
    UVS.Upvotes,
    UVS.Downvotes,
    TA.Title AS TopPostTitle,
    TA.Score AS TopPostScore,
    UA.PostsCreated,
    UA.CommentsMade,
    UA.EditsMade
FROM UserVoteStats UVS
JOIN UserActivity UA ON UVS.UserId = UA.UserId
LEFT JOIN TopPosts TA ON UA.PostsCreated > 0
WHERE UVS.Upvotes - UVS.Downvotes > 0
ORDER BY UVS.Upvotes DESC, UVS.Downvotes ASC;
