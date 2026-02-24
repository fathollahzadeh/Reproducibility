
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
), RichStats AS (
    SELECT 
        UB.DisplayName,
        COALESCE(PS.QuestionCount, 0) AS Questions,
        COALESCE(PS.AnswerCount, 0) AS Answers,
        COALESCE(PS.TotalScore, 0) AS Score,
        COALESCE(PS.TotalViews, 0) AS Views,
        UB.BadgeCount, 
        UB.GoldBadges, 
        UB.SilverBadges, 
        UB.BronzeBadges
    FROM UserBadges UB
    LEFT JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    R.DisplayName,
    R.Questions,
    R.Answers,
    R.Score,
    R.Views,
    R.BadgeCount,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    R.BadgeCount / NULLIF(R.Questions, 0) AS BadgePerQuestion,
    R.BadgeCount / NULLIF(R.Answers, 0) AS BadgePerAnswer
FROM RichStats R
WHERE R.BadgeCount > 0
ORDER BY R.Score DESC, R.DisplayName ASC;
