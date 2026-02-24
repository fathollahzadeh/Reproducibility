WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.Reputation
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    US.PostCount,
    US.TotalScore,
    US.TotalViews,
    US.TotalCommentScore,
    US.QuestionCount,
    US.AnswerCount,
    BS.BadgeCount,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges
FROM Users U
JOIN UserStats US ON U.Id = US.UserId
LEFT JOIN BadgeStats BS ON U.Id = BS.UserId
ORDER BY US.TotalScore DESC
LIMIT 10;