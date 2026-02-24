WITH UserBadgeCounts AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT p.OwnerUserId,
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
           COUNT(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
           SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.DisplayName,
           COALESCE(ub.GoldBadges, 0) AS GoldBadges,
           COALESCE(ub.SilverBadges, 0) AS SilverBadges,
           COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
           COALESCE(ps.Questions, 0) AS Questions,
           COALESCE(ps.AcceptedAnswers, 0) AS AcceptedAnswers,
           COALESCE(ps.TotalViews, 0) AS TotalViews,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
)
SELECT ua.UserId, 
       ua.DisplayName,
       ua.Reputation,
       ua.GoldBadges,
       ua.SilverBadges,
       ua.BronzeBadges,
       ua.Questions,
       ua.AcceptedAnswers,
       ua.TotalViews,
       ua.Rank
FROM UserActivity ua
WHERE (ua.Reputation > 50 OR ua.GoldBadges > 0)
  AND ua.Questions > (SELECT AVG(Questions) FROM PostStatistics)
ORDER BY ua.Rank
LIMIT 10;
