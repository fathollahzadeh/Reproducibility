
WITH UserBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS BadgeCount, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT p.OwnerUserId, COUNT(DISTINCT p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
           SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS FavoritedPosts
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT u.Id, u.DisplayName, ub.BadgeCount, ps.TotalPosts, 
           ps.Questions, ps.Answers, ps.ClosedPosts, ps.FavoritedPosts
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    WHERE u.Reputation > 1000
),
TopContributors AS (
    SELECT DisplayName, BadgeCount, TotalPosts, Questions, Answers, ClosedPosts, FavoritedPosts,
           RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM ActiveUsers
)
SELECT DisplayName, BadgeCount, TotalPosts, Questions, Answers, ClosedPosts, FavoritedPosts
FROM TopContributors
WHERE PostRank <= 10
ORDER BY PostRank;
