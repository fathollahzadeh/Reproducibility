WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.PostCount,
        UR.QuestionCount,
        UR.AnswerCount,
        COALESCE(BS.BadgeCount, 0) AS BadgeCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserReputation UR
    LEFT JOIN 
        BadgeSummary BS ON UR.UserId = BS.UserId
    ORDER BY 
        UR.Reputation DESC, UR.PostCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.BadgeCount,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.QuestionCount > 5
ORDER BY 
    T.Reputation DESC;
