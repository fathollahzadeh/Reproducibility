
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvotesGiven,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvotesGiven,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostInteraction AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PT.Name AS PostHistoryType,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS Closures
    FROM PostHistory PH
    JOIN PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId, PH.CreationDate, PT.Name
),
AggregatedData AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Rank,
        COALESCE(UI.UpvotesGiven, 0) AS UpvotesGiven,
        COALESCE(UI.DownvotesGiven, 0) AS DownvotesGiven,
        COALESCE(PI.CommentCount, 0) AS TotalComments,
        COALESCE(CL.Closures, 0) AS NumberOfClosures
    FROM RankedPosts R
    LEFT JOIN UserActivity UI ON R.PostId = UI.UserId
    LEFT JOIN PostInteraction PI ON R.PostId = PI.PostId
    LEFT JOIN ClosedPosts CL ON R.PostId = CL.PostId
)
SELECT 
    A.PostId,
    A.Title,
    A.Rank,
    A.UpvotesGiven,
    A.DownvotesGiven,
    A.TotalComments,
    A.NumberOfClosures,
    CASE 
        WHEN A.NumberOfClosures > 0 THEN 'Closed'
        WHEN A.UpvotesGiven > A.DownvotesGiven THEN 'Popular'
        ELSE 'Discussion'
    END AS PostStatus
FROM AggregatedData A
WHERE A.Rank <= 10
ORDER BY A.Rank;
