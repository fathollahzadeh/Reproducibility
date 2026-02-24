
WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges, 
           COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges, 
           COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           AVG(p.Score) AS AverageScore,
           MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserEngagement AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(ub.GoldBadges, 0) AS GoldBadges,
           COALESCE(ub.SilverBadges, 0) AS SilverBadges,
           COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
           ps.TotalPosts,
           ps.Questions,
           ps.Answers,
           ps.AverageScore,
           ps.LastPostDate,
           DENSE_RANK() OVER (PARTITION BY 
               CASE 
                   WHEN COALESCE(ub.GoldBadges, 0) > 0 THEN 1
                   WHEN COALESCE(ub.SilverBadges, 0) > 0 THEN 2
                   ELSE 3 
               END 
               ORDER BY ps.TotalPosts DESC) AS RankWithinBadgeClass
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
)
SELECT ue.*, 
       CASE WHEN ue.Answers > 0 THEN (ue.Questions::decimal / ue.Answers) ELSE NULL END AS QuestionToAnswerRatio,
       CASE WHEN ue.LastPostDate IS NOT NULL THEN 
           EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - ue.LastPostDate)) / 86400 
       ELSE NULL 
       END AS DaysSinceLastPost
FROM UserEngagement ue
WHERE (ue.TotalPosts > 10 OR ue.GoldBadges > 0)
  AND (ue.AverageScore IS NOT NULL AND ue.AverageScore > 5)
ORDER BY ue.RankWithinBadgeClass, ue.TotalPosts DESC;
