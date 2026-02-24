
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosedPostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
), RankStats AS (
    SELECT 
        UserId, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM UserStats
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.AnswersCount,
        US.QuestionsCount,
        US.ClosedPostCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
        RS.ReputationRank,
        RS.PostCountRank
    FROM UserStats US
    LEFT JOIN BadgeSummary BS ON US.UserId = BS.UserId
    LEFT JOIN RankStats RS ON US.UserId = RS.UserId
)
SELECT 
    CB.DisplayName,
    CB.Reputation,
    CB.PostCount,
    CB.AnswersCount,
    CB.QuestionsCount,
    CB.ClosedPostCount,
    CB.GoldBadges,
    CB.SilverBadges,
    CB.BronzeBadges,
    CB.ReputationRank,
    CB.PostCountRank,
    CASE 
        WHEN CB.ClosedPostCount > 0 THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS ClosedPostStatus,
    CASE
        WHEN CB.Reputation > 1000 THEN 'High Reputation'
        WHEN CB.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier
FROM CombinedStats CB
WHERE CB.PostCount > 5
ORDER BY CB.Reputation DESC, CB.PostCount DESC
LIMIT 10 OFFSET 5;
