WITH UserBadges AS (
    SELECT UserId,
           COUNT(*) AS TotalBadges,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT OwnerUserId,
           COUNT(DISTINCT Id) AS TotalPosts,
           SUM(COALESCE(Score, 0)) AS TotalScore,
           SUM(COALESCE(ViewCount, 0)) AS TotalViews,
           AVG(COALESCE(AnswerCount, 0)) AS AverageAnswers
    FROM Posts
    GROUP BY OwnerUserId
),
UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           U.Views,
           UB.TotalBadges,
           UB.GoldBadges,
           UB.SilverBadges,
           UB.BronzeBadges,
           PS.TotalPosts,
           PS.TotalScore,
           PS.TotalViews,
           PS.AverageAnswers
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT UA.UserId,
       UA.DisplayName,
       COALESCE(UA.TotalPosts, 0) AS TotalPosts,
       COALESCE(UA.TotalScore, 0) AS TotalScore,
       COALESCE(UA.TotalViews, 0) AS TotalViews,
       UA.Reputation,
       UA.Views,
       COALESCE(UA.TotalBadges, 0) AS TotalBadges,
       COALESCE(UA.GoldBadges, 0) AS GoldBadges,
       COALESCE(UA.SilverBadges, 0) AS SilverBadges,
       COALESCE(UA.BronzeBadges, 0) AS BronzeBadges,
       CASE 
           WHEN UA.Reputation >= 1000 THEN 'Active'
           WHEN UA.Reputation BETWEEN 500 AND 999 THEN 'Moderate'
           ELSE 'Inactive' 
       END AS ActivityLevel
FROM UserActivity UA
ORDER BY UA.Reputation DESC
LIMIT 20;
