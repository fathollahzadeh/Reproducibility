WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT V.PostId) AS TotalPostsVoted
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MIN(PHT.Name) AS FirstAction,
        COUNT(PH.Id) AS TotalActions,
        MIN(PH.CreationDate) AS FirstActionDate,
        MAX(PH.CreationDate) AS LastActionDate
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalPostsVoted,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.CommentCount,
    PHS.FirstAction,
    PHS.TotalActions,
    PHS.FirstActionDate,
    PHS.LastActionDate,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = R.PostId AND V.VoteTypeId = 2), 0) AS UpvoteCount,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = R.PostId AND V.VoteTypeId = 3), 0) AS DownvoteCount
FROM UserVoteStats U
JOIN RecentPosts R ON R.OwnerUserId = U.UserId
LEFT JOIN PostHistorySummary PHS ON R.PostId = PHS.PostId
WHERE U.TotalPostsVoted > 10 
AND R.RowNum <= 10 
ORDER BY U.TotalUpvotes DESC, R.CreationDate DESC;