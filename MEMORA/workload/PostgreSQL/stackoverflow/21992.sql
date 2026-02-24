
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate))) AS AvgAnswerTime,
        COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
FilteredUsers AS (
    SELECT 
        U.UserId, 
        U.Reputation, 
        U.TotalBadges, 
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.TotalQuestions,
        P.TotalAnswers,
        P.AvgAnswerTime,
        P.TotalScore    
    FROM UserBadges U
    LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
    WHERE U.Reputation > 100 AND U.TotalBadges > 5
),
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY GoldBadges ORDER BY TotalScore DESC, Reputation DESC) AS RankByGold,
        DENSE_RANK() OVER (ORDER BY AvgAnswerTime ASC) AS RankByResponseTime
    FROM FilteredUsers
)
SELECT 
    Us.DisplayName, 
    U.Reputation, 
    U.TotalBadges, 
    U.GoldBadges, 
    U.SilverBadges,
    U.BronzeBadges,
    U.TotalQuestions, 
    U.TotalAnswers,
    CAST(U.AvgAnswerTime AS INTEGER) AS AvgResponseTimeInSeconds,
    U.RankByGold,
    U.RankByResponseTime
FROM RankedUsers U
INNER JOIN Users Us ON U.UserId = Us.Id
WHERE 
    U.RankByGold = 1 
    AND U.RankByResponseTime <= 5 
    AND (U.TotalAnswers IS NOT NULL OR U.TotalQuestions IS NOT NULL)
ORDER BY U.TotalScore DESC, U.Reputation DESC
LIMIT 10;
