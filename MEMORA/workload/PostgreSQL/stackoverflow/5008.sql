
WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
PostStats AS (
    SELECT P.OwnerUserId, 
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(P.Score) AS TotalScore,
           SUM(P.ViewCount) AS TotalViews,
           AVG(EXTRACT(EPOCH FROM (P.CreationDate - U.CreationDate)) / 86400) AS AverageAccountAge
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY P.OwnerUserId
),
UserPerformance AS (
    SELECT UB.UserId,
           COALESCE(UB.GoldBadges, 0) AS GoldBadges,
           COALESCE(UB.SilverBadges, 0) AS SilverBadges,
           COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
           COALESCE(PS.QuestionCount, 0) AS QuestionsPosted,
           COALESCE(PS.AnswerCount, 0) AS AnswersPosted,
           COALESCE(PS.TotalScore, 0) AS Score,
           COALESCE(PS.TotalViews, 0) AS Views,
           PS.AverageAccountAge
    FROM UserBadges UB
    FULL OUTER JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT UP.UserId, 
       U.DisplayName,
       UP.GoldBadges, 
       UP.SilverBadges, 
       UP.BronzeBadges, 
       UP.QuestionsPosted, 
       UP.AnswersPosted, 
       UP.Score, 
       UP.Views, 
       UP.AverageAccountAge
FROM UserPerformance UP
JOIN Users U ON UP.UserId = U.Id
WHERE U.Reputation > 100
ORDER BY UP.Score DESC, U.Reputation DESC 
LIMIT 10;
