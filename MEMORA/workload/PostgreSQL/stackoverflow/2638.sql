WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), PostStatistics AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COUNT(DISTINCT RP.PostId) AS TotalPosts,
        COALESCE(SUM(RP.Score), 0) AS TotalScore,
        COALESCE(SUM(RP.ViewCount), 0) AS TotalViews
    FROM UserReputation U
    LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
    GROUP BY U.UserId, U.DisplayName
), VoteCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(V.Id) AS TotalVotes
    FROM Posts P
    JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
)
SELECT 
    PS.UserId,
    PS.DisplayName,
    PS.TotalPosts,
    PS.TotalScore,
    PS.TotalViews,
    COALESCE(VC.TotalVotes, 0) AS TotalVotes,
    R.ReputationRank
FROM PostStatistics PS
LEFT JOIN VoteCounts VC ON PS.UserId = VC.OwnerUserId
JOIN UserReputation R ON PS.UserId = R.UserId
WHERE PS.TotalPosts > 10
  AND PS.TotalScore > 100
ORDER BY PS.TotalScore DESC, R.ReputationRank ASC
LIMIT 5;