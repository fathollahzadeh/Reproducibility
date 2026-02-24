WITH User_PostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
BadgeStats AS (
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
CombinedStats AS (
    SELECT
        UPS.UserId,
        UPS.DisplayName,
        UPS.PostCount,
        UPS.QuestionCount,
        UPS.AnswerCount,
        UPS.TotalViews,
        UPS.TotalScore,
        COALESCE(BS.BadgeCount, 0) AS BadgeCount,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM
        User_PostStats UPS
    LEFT JOIN
        BadgeStats BS ON UPS.UserId = BS.UserId
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM
    CombinedStats
ORDER BY
    TotalScore DESC,
    PostCount DESC
LIMIT 10;