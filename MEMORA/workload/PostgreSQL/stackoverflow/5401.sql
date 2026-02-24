
WITH TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM
        TopUsers
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM
        Badges B
    JOIN
        Users U ON B.UserId = U.Id
    GROUP BY
        U.Id
)
SELECT
    AU.UserId,
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.TotalScore,
    AU.QuestionCount,
    AU.AnswerCount,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(UB.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM
    ActiveUsers AU
LEFT JOIN
    UserBadges UB ON AU.UserId = UB.UserId
WHERE
    AU.ScoreRank <= 10 OR AU.PostRank <= 10
ORDER BY
    AU.TotalScore DESC, AU.PostCount DESC;
