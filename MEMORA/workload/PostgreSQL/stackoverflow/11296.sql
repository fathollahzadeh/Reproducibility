WITH UserVoteCounts AS (
    SELECT 
        V.UserId, 
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM Votes V
    GROUP BY V.UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.OwnerUserId
),
UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(PS.CommentCount) AS TotalComments,
        SUM(PS.TotalViews) AS TotalViews,
        SUM(PS.TotalScore) AS TotalScore
    FROM Users U
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UPC.PostCount,
    UPC.TotalComments,
    UPC.TotalViews,
    UPC.TotalScore,
    UVC.VoteCount,
    UVC.UpvoteCount,
    UVC.DownvoteCount
FROM Users U
JOIN UserPostStatistics UPC ON U.Id = UPC.UserId
LEFT JOIN UserVoteCounts UVC ON U.Id = UVC.UserId
ORDER BY U.Reputation DESC;