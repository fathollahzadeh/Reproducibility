
WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScorePosts,
        COALESCE(AVG(P.Score), 0) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        PositiveScorePosts,
        AverageScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
    WHERE TotalPosts > 0
),
HighScoringUsers AS (
    SELECT 
        T.DisplayName,
        T.TotalQuestions,
        T.TotalAnswers,
        T.PositiveScorePosts,
        T.AverageScore,
        COUNT(CASE WHEN B.Name = 'Gold' THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Name = 'Silver' THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Name = 'Bronze' THEN 1 END) AS BronzeBadges
    FROM TopUsers T
    LEFT JOIN Badges B ON T.UserId = B.UserId
    WHERE T.AverageScore > 10
    GROUP BY T.DisplayName, T.TotalQuestions, T.TotalAnswers, T.PositiveScorePosts, T.AverageScore
)
SELECT 
    H.DisplayName,
    H.TotalQuestions,
    H.TotalAnswers,
    H.PositiveScorePosts,
    H.AverageScore,
    COALESCE(H.GoldBadges, 0) AS GoldBadges,
    COALESCE(H.SilverBadges, 0) AS SilverBadges,
    COALESCE(H.BronzeBadges, 0) AS BronzeBadges
FROM HighScoringUsers H
WHERE H.TotalQuestions > 5
ORDER BY H.AverageScore DESC, H.PositiveScorePosts DESC
FETCH FIRST 10 ROWS ONLY;
