WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.QuestionCount,
        UR.AnswerCount,
        AB.GoldBadges,
        AB.SilverBadges,
        AB.BronzeBadges,
        UR.TotalBounty
    FROM UserReputation UR
    LEFT JOIN ActiveBadges AB ON UR.UserId = AB.UserId
    ORDER BY UR.Reputation DESC, UR.PostCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(TU.GoldBadges, 0) AS GoldBadges,
    COALESCE(TU.SilverBadges, 0) AS SilverBadges,
    COALESCE(TU.BronzeBadges, 0) AS BronzeBadges,
    TU.TotalBounty
FROM TopUsers TU;