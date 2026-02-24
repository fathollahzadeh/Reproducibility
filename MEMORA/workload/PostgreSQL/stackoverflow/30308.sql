WITH RECURSIVE UserReputationCTE AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        CAST(0 AS int) AS Level
    FROM Users U
    WHERE U.Reputation IS NOT NULL
    UNION ALL
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        C.Level + 1
    FROM Users U
    JOIN UserReputationCTE C ON U.Reputation >= C.Reputation + 1000
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        Dense_Rank() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 1000
),
PostActivity AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(CASE WHEN P.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN P.Score END) AS AvgScoreLast30Days
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(PA.PostCount, 0) AS TotalPosts,
    COALESCE(PA.TotalScore, 0) AS TotalScore,
    COALESCE(PA.AvgScoreLast30Days, 0) AS AvgScoreLast30Days,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS OverallRank
FROM Users U
LEFT JOIN PostActivity PA ON U.Id = PA.OwnerUserId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY U.Reputation DESC
LIMIT 100;