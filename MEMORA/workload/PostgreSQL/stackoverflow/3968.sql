WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
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
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
), 
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS ClosedCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(RP.PostCount, 0) AS TotalPosts,
    COALESCE(RP.QuestionsCount, 0) AS TotalQuestions,
    COALESCE(RP.AnswersCount, 0) AS TotalAnswers,
    COALESCE(CP.ClosedCount, 0) AS TotalClosedPosts
FROM RankedUsers U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
LEFT JOIN ClosedPosts CP ON U.UserId = CP.UserId
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC;