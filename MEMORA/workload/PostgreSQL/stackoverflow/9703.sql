WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounty,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY U.Id
), BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.AnswerCount,
        US.QuestionCount,
        US.TotalBounty,
        COALESCE(BS.BadgeCount, 0) AS BadgeCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
        US.ReputationRank
    FROM UserStats US
    LEFT JOIN BadgeStats BS ON US.UserId = BS.UserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.Reputation,
    C.PostCount,
    C.AnswerCount,
    C.QuestionCount,
    C.TotalBounty,
    C.BadgeCount,
    C.GoldBadges,
    C.SilverBadges,
    C.BronzeBadges,
    C.ReputationRank
FROM CombinedStats C
WHERE C.ReputationRank <= 100
ORDER BY C.Reputation DESC, C.PostCount DESC
LIMIT 10;