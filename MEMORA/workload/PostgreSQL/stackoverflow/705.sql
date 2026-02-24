WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
HighScorePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY AVG(P.Score) DESC) AS Rank
    FROM Posts P
    WHERE P.Score IS NOT NULL
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    UBadge.GoldBadges,
    UBadge.SilverBadges,
    UBadge.BronzeBadges,
    HScore.TotalPosts,
    HScore.AvgScore,
    CASE 
        WHEN HScore.AvgScore IS NULL THEN 'No Posts'
        WHEN HScore.AvgScore > 50 THEN 'High Performer'
        WHEN HScore.AvgScore BETWEEN 20 AND 50 THEN 'Moderate Performer'
        ELSE 'Needs Improvement' 
    END AS PerformanceCategory
FROM Users U
LEFT JOIN UserBadgeStats UBadge ON U.Id = UBadge.UserId
LEFT JOIN HighScorePosts HScore ON U.Id = HScore.OwnerUserId
WHERE U.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR'
AND (UBadge.TotalBadges IS NULL OR UBadge.TotalBadges > 0)
ORDER BY U.DisplayName ASC, HScore.AvgScore DESC NULLS LAST;