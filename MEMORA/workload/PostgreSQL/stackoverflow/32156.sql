WITH RecursiveUserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        B.Name AS BadgeName,
        DENSE_RANK() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
    WHERE B.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM RecursiveUserBadges
    GROUP BY UserId, DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(TU.TotalBadges, 0) AS TotalBadges,
        COALESCE(TU.GoldBadges, 0) AS GoldBadges,
        COALESCE(TU.SilverBadges, 0) AS SilverBadges,
        COALESCE(TU.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM Users U
    LEFT JOIN TopUsers TU ON U.Id = TU.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews
FROM CombinedStats
WHERE TotalBadges > 0 OR QuestionCount > 0
ORDER BY TotalScore DESC, TotalBadges DESC
LIMIT 10;