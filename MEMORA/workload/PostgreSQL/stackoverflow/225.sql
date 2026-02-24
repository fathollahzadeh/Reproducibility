
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END) AS TotalVoteBalance
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS TotalComments,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), P.Id) AS EffectiveAcceptedAnswerId,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(POST_METRICS.TotalComments, 0)) AS TotalComments,
        SUM(COALESCE(POST_METRICS.CloseReopenCount, 0)) AS CloseReopenCount,
        SUM(UPV.TotalVoteBalance) AS UserVoteBalance
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostMetrics POST_METRICS ON P.Id = POST_METRICS.PostId
    LEFT JOIN 
        UserVotes UPV ON U.Id = UPV.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.CloseReopenCount,
    COALESCE(U.UserVoteBalance, 0) AS UserVoteBalance,
    (SELECT COUNT(*) FROM Posts P WHERE P.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR')) AS RecentPostsCount,
    (SELECT COUNT(*) FROM Users WHERE Reputation > 1000) AS HighReputationUsers
FROM 
    UserPostStats U
WHERE 
    U.TotalPosts > 10
ORDER BY 
    U.UserVoteBalance DESC, U.TotalPosts DESC
LIMIT 50;
