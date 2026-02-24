WITH AggregateBadges AS (
    SELECT UserId, 
           COUNT(*) AS TotalBadges,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostMetrics AS (
    SELECT OwnerUserId,
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(ViewCount) AS TotalViews,
           SUM(AnswerCount) AS TotalAcceptedAnswers
    FROM Posts
    GROUP BY OwnerUserId
),
UserStatistics AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           U.CreationDate,
           AB.TotalBadges,
           AB.GoldBadges,
           AB.SilverBadges,
           AB.BronzeBadges,
           PM.TotalPosts,
           PM.TotalQuestions,
           PM.TotalAnswers,
           PM.TotalViews,
           PM.TotalAcceptedAnswers
    FROM Users U
    LEFT JOIN AggregateBadges AB ON U.Id = AB.UserId
    LEFT JOIN PostMetrics PM ON U.Id = PM.OwnerUserId
)
SELECT UserId,
       DisplayName,
       Reputation,
       CreationDate,
       TotalBadges,
       GoldBadges,
       SilverBadges,
       BronzeBadges,
       TotalPosts,
       TotalQuestions,
       TotalAnswers,
       TotalViews,
       TotalAcceptedAnswers
FROM UserStatistics
WHERE Reputation > 100
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 10;
