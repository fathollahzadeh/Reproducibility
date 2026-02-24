WITH UserBadges AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(b.Id) AS BadgeCount, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), UserPosts AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers, 
           SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
), UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COALESCE(up.TotalPosts, 0) AS TotalPosts, 
           COALESCE(up.Questions, 0) AS Questions, 
           COALESCE(up.Answers, 0) AS Answers, 
           COALESCE(up.TotalViews, 0) AS TotalViews,
           ub.BadgeCount,
           ub.GoldBadges,
           ub.SilverBadges,
           ub.BronzeBadges
    FROM Users u
    LEFT JOIN UserPosts up ON u.Id = up.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT UserId, 
       DisplayName, 
       TotalPosts, 
       Questions, 
       Answers, 
       TotalViews, 
       BadgeCount, 
       GoldBadges, 
       SilverBadges, 
       BronzeBadges
FROM UserActivity
WHERE TotalPosts > 0
ORDER BY TotalViews DESC, BadgeCount DESC
LIMIT 10;
