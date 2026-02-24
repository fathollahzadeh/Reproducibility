WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScores,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeScores,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
), CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UR.Reputation, 0) AS Reputation,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.PositiveScores, 0) AS PositiveScores,
        COALESCE(PS.NegativeScores, 0) AS NegativeScores,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        UR.ReputationRank
    FROM Users U
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    WHERE U.Reputation > 0
), FinalResults AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC) AS OverallRank
    FROM CombinedStats
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    PositiveScores,
    NegativeScores,
    BadgeCount,
    OverallRank
FROM FinalResults
WHERE OverallRank <= 10
ORDER BY OverallRank;
