
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.PositivePosts, 0) AS PositivePosts,
        COALESCE(PS.NegativePosts, 0) AS NegativePosts,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
    WHERE UR.Reputation > 1000
),
ClosedPostCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ClosedPostCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.UserId
),
FinalStatistics AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.TotalPosts,
        TU.PositivePosts,
        TU.NegativePosts,
        TU.AverageScore,
        COALESCE(CPC.ClosedPostCount, 0) AS ClosedPostCount,
        UR.ReputationRank
    FROM TopUsers TU
    LEFT JOIN ClosedPostCounts CPC ON TU.UserId = CPC.UserId
    JOIN UserReputation UR ON TU.UserId = UR.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    PositivePosts,
    NegativePosts,
    ClosedPostCount,
    CASE 
        WHEN ReputationRank <= 5 THEN 'Top Contributor'
        WHEN Reputation >= 2000 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorCategory
FROM FinalStatistics
WHERE ReputationRank <= 10
ORDER BY Reputation DESC, TotalPosts DESC;
