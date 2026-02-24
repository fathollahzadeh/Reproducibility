WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        U.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN U.Reputation IS NULL THEN 'NULL' ELSE 'NOT_NULL' END ORDER BY U.Reputation DESC) AS Rank,
        CASE WHEN U.Reputation IS NULL THEN 'Unranked' ELSE 'Ranked' END AS ReputationStatus
    FROM Users U
    WHERE U.Reputation IS NOT NULL OR U.Reputation IS NULL
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(P.NegativePosts, 0) AS NegativePosts,
        COALESCE(P.AvgScore, 0) AS AvgScore
    FROM Users U
    LEFT JOIN PostStatistics P ON U.Id = P.OwnerUserId
    LEFT JOIN UserBadges B ON U.Id = B.UserId
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.NegativePosts,
    UA.AvgScore,
    CASE 
        WHEN UA.AvgScore < 0 THEN 'Needs Improvement'
        WHEN UA.AvgScore = 0 THEN 'Neutral'
        ELSE 'Good Score'
    END AS ScoreEvaluation,
    R.Rank,
    R.ReputationStatus
FROM UserActivity UA
JOIN RankedUsers R ON UA.UserId = R.UserId
WHERE UA.TotalPosts > (
    SELECT AVG(TotalPosts) FROM PostStatistics
    HAVING COUNT(*) > 1
)
OR UA.GoldBadges > 2
ORDER BY UA.TotalPosts DESC, R.Reputation DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;