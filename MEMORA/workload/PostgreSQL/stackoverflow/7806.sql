WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        COUNT(DISTINCT P.Id) AS PostsVotedOn,
        AVG(P.Score) AS AvgScoreOnVotedPosts
    FROM Users U
    JOIN Votes V ON V.UserId = U.Id
    JOIN Posts P ON P.Id = V.PostId
    GROUP BY U.Id
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY P.Id
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.UpvoteCount,
        PS.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY PS.CommentCount DESC, PS.UpvoteCount DESC) AS Rank
    FROM PostEngagement PS
)
SELECT 
    U.UserId,
    U.DisplayName,
    TP.Title,
    TP.CommentCount,
    TP.UpvoteCount,
    TP.DownvoteCount,
    U.VoteCount,
    U.PostsVotedOn,
    U.AvgScoreOnVotedPosts
FROM UserVoteSummary U
JOIN TopPosts TP ON U.VoteCount > 0
WHERE TP.Rank <= 10
ORDER BY U.VoteCount DESC, TP.UpvoteCount DESC;