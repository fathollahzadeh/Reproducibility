WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS TotalComments,
        AVG(P.Score) AS AverageScore,
        SUM(V.BountyAmount) AS TotalBounty,
        MAX(P.CreationDate) AS MostRecentActivity
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY P.Id, P.Title
),
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        MAX(PH.CreationDate) AS LastCloseDate,
        COUNT(*) AS TotalCloseReasons
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10  
    GROUP BY PH.PostId, PH.UserId
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.UpVotes,
        U.DownVotes,
        P.Title,
        P.TotalComments,
        P.AverageScore,
        COALESCE(CPS.TotalCloseReasons, 0) AS TotalCloseReasons,
        P.TotalBounty,
        P.MostRecentActivity,
        CASE 
            WHEN CPS.LastCloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM UserVoteCounts U
    JOIN PostStatistics P ON U.TotalPosts > 0
    LEFT JOIN ClosedPostStats CPS ON CPS.PostId = P.PostId
    ORDER BY U.UpVotes DESC, P.AverageScore DESC
)
SELECT 
    *,
    CONCAT(DisplayName, ' has ', UpVotes, ' upvotes and ', DownVotes, ' downvotes. The post "', Title, '" has ', TotalComments, ' comments and an average score of ', AverageScore, '. The post is currently ', PostStatus, '.' ) AS PostSummary
FROM FinalStats
WHERE TotalBounty IS NOT NULL OR TotalCloseReasons > 0;