
WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, CreationDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN VH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory VH ON P.Id = VH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName
),
CombinedStats AS (
    SELECT 
        UR.Id AS UserId,
        UR.Reputation,
        PostStats.PostId,
        PostStats.Title,
        PostStats.CreationDate,
        PostStats.Score,
        PostStats.ViewCount,
        RecentUserActivity.PostsCreated,
        RecentUserActivity.TotalViews,
        RecentUserActivity.AverageScore,
        PostStats.CloseCount
    FROM UserReputationCTE UR
    LEFT JOIN PostStats ON UR.ReputationRank = 1
    LEFT JOIN RecentUserActivity ON UR.Id = RecentUserActivity.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    C.PostId,
    C.Title,
    C.ViewCount,
    C.Reputation,
    C.PostsCreated,
    C.TotalViews,
    C.AverageScore,
    CASE 
        WHEN C.CloseCount > 0 THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM CombinedStats C
JOIN Users U ON C.UserId = U.Id
WHERE C.Reputation > 1000
ORDER BY C.Reputation DESC, C.ViewCount DESC
LIMIT 100;
