WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation > 1000
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), UserPostStatistics AS (
    SELECT 
        U.DisplayName,
        COUNT(RP.PostId) AS TotalPosts,
        SUM(RP.ViewCount) AS TotalViews,
        SUM(RP.Score) AS TotalScore
    FROM TopUsers U
    LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
    GROUP BY U.DisplayName
), CombinedStats AS (
    SELECT 
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalViews,
        UPS.TotalScore,
        U.Reputation,
        RANK() OVER (ORDER BY UPS.TotalScore DESC) AS ScoreRank
    FROM UserPostStatistics UPS
    JOIN TopUsers U ON UPS.DisplayName = U.DisplayName
)
SELECT 
    CS.DisplayName,
    CS.TotalPosts,
    CS.TotalViews,
    CS.TotalScore,
    CS.Reputation,
    CS.ScoreRank
FROM CombinedStats CS
WHERE CS.ScoreRank <= 10
ORDER BY CS.ScoreRank;