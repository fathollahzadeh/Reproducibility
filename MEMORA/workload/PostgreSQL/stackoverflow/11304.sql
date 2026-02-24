WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
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
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM
        Badges B
    GROUP BY
        B.UserId
)
SELECT
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.TotalScore,
    US.QuestionCount,
    US.AnswerCount,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(BS.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM
    UserStats US
LEFT JOIN
    BadgeStats BS ON US.UserId = BS.UserId
ORDER BY
    US.Reputation DESC, US.TotalScore DESC;