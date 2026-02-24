
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalUpDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS EngagementRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalBounties DESC) AS Rank
    FROM UserEngagement
    WHERE TotalPosts > 0
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(COUNT(H.Id), 0) AS HistoryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory H ON P.Id = H.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
ActivePosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.CommentCount,
        PS.HistoryCount,
        RANK() OVER (ORDER BY PS.Score DESC, PS.CommentCount DESC) AS PopularityRank
    FROM PostStats PS
    WHERE PS.CommentCount > 0
)

SELECT 
    U.DisplayName AS User,
    U.TotalBounties,
    UP.Title AS TopPost,
    UP.Score AS PostScore,
    UP.CommentCount,
    UP.PopularityRank AS PostPopularityRank,
    T.TotalVotes,
    T.EngagementRank
FROM TopUsers T
JOIN UserEngagement U ON T.UserId = U.UserId
LEFT JOIN ActivePosts UP ON U.UserId = UP.PostId
WHERE U.EngagementRank <= 10
ORDER BY U.TotalBounties DESC, U.TotalVotes DESC;
