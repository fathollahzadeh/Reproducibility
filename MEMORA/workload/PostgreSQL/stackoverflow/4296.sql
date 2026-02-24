WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY SUM(U.Reputation) DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBountyCreated
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 2) 
    GROUP BY P.Id, P.Title
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ClosureCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)

SELECT 
    U.DisplayName,
    U.TotalBounty,
    U.TotalPosts,
    U.TotalComments,
    PS.CommentCount AS PostCommentCount,
    PS.TotalBountyCreated AS PostBountyCount,
    COALESCE(CP.ClosureCount, 0) AS ClosureCount,
    CP.LastClosedDate
FROM UserReputation U
JOIN PostStatistics PS ON U.UserId = PS.PostId
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
WHERE U.ReputationRank <= 50 
ORDER BY U.TotalBounty DESC, U.DisplayName;