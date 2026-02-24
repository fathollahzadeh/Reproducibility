WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        SUM(CASE WHEN P.Score > 10 THEN 1 ELSE 0 END) AS HighScorePostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
Engagement AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        BB.GoldBadges,
        BB.SilverBadges,
        BB.BronzeBadges,
        UR.PostCount,
        UR.QuestionCount,
        UR.AnswerCount,
        UR.PopularPostCount,
        UR.HighScorePostCount
    FROM 
        UserReputation UR
    LEFT JOIN 
        BadgeStats BB ON UR.UserId = BB.UserId
)
SELECT 
    E.UserId,
    E.Reputation,
    E.GoldBadges,
    E.SilverBadges,
    E.BronzeBadges,
    E.PostCount,
    E.QuestionCount,
    E.AnswerCount,
    E.PopularPostCount,
    E.HighScorePostCount,
    (CASE 
        WHEN E.Reputation > 5000 THEN 'Expert' 
        WHEN E.Reputation BETWEEN 1000 AND 5000 THEN 'Experienced' 
        ELSE 'Novice' 
    END) AS UserLevel
FROM 
    Engagement E
ORDER BY 
    E.Reputation DESC, E.PostCount DESC;
