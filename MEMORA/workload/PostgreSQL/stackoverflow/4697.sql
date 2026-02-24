
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        AnswerCount,
        QuestionCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.Views,
    RU.AnswerCount,
    RU.QuestionCount,
    RU.GoldBadges,
    RU.SilverBadges,
    RU.BronzeBadges,
    CONCAT('Rank: ', CAST(RU.ReputationRank AS VARCHAR)) AS Ranking
FROM RankedUsers RU
WHERE RU.AnswerCount > 5 
  AND RU.ReputationRank <= 100
  AND (RU.GoldBadges > 0 OR RU.SilverBadges > 0)
ORDER BY RU.Reputation DESC;
