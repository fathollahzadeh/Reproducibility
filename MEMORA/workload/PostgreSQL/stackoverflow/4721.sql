
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
BadgesCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
FinalStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
        UR.UserRank,
        UR.Reputation
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
    LEFT JOIN BadgesCount BC ON UR.UserId = BC.UserId
)
SELECT 
    F.DisplayName,
    F.QuestionCount,
    F.AnswerCount,
    F.TotalScore,
    F.BadgeCount,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges,
    F.UserRank
FROM FinalStats F
WHERE F.Reputation > 1000 
ORDER BY F.TotalScore DESC, F.BadgeCount DESC
FETCH FIRST 10 ROWS ONLY;
