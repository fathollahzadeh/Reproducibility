
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY P.OwnerUserId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(UBC.TotalPosts, 0) AS TotalPosts,
        COALESCE(UBC.Questions, 0) AS TotalQuestions,
        COALESCE(UBC.Answers, 0) AS TotalAnswers,
        UBC2.GoldBadges,
        UBC2.SilverBadges,
        UBC2.BronzeBadges
    FROM Users U
    LEFT JOIN PostSummary UBC ON U.Id = UBC.OwnerUserId
    LEFT JOIN UserBadgeCounts UBC2 ON U.Id = UBC2.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges
FROM UserStatistics US
WHERE (US.TotalPosts > 0 OR US.Reputation > 1000)
ORDER BY US.Reputation DESC, US.TotalPosts DESC
LIMIT 50;
