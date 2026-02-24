WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AverageViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpvotes,
        TotalDownvotes,
        TotalPosts,
        AverageViewCount,
        ROW_NUMBER() OVER (ORDER BY TotalUpvotes DESC) AS Rank
    FROM UserVoteStats
    WHERE TotalPosts > 0
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        PH.CreationDate AS ClosedDate
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10
),
UserPostClosedStats AS (
    SELECT 
        C.OwnerUserId,
        COUNT(DISTINCT C.PostId) AS TotalClosedPosts,
        MIN(C.ClosedDate) AS FirstClosedDate
    FROM ClosedPosts C
    GROUP BY C.OwnerUserId
)

SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalUpvotes,
    T.TotalDownvotes,
    T.TotalPosts,
    T.AverageViewCount,
    COALESCE(U.TotalClosedPosts, 0) AS TotalClosedPosts,
    U.FirstClosedDate,
    CASE 
        WHEN T.TotalUpvotes - T.TotalDownvotes > 10 THEN 'Active Contributor'
        WHEN T.TotalUpvotes - T.TotalDownvotes < 0 THEN 'Negative Feedback'
        ELSE 'Moderate Activity'
    END AS UserActivityStatus
FROM TopUsers T
LEFT JOIN UserPostClosedStats U ON T.UserId = U.OwnerUserId
WHERE T.Rank <= 10
ORDER BY T.TotalUpvotes DESC, T.TotalDownvotes ASC;
