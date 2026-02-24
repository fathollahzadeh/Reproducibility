WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges 
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT P.OwnerUserId,
           COUNT(P.Id) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
), 
UserEngagement AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           U.Views, 
           COALESCE(PostStats.TotalPosts, 0) AS TotalPosts, 
           COALESCE(PostStats.Questions, 0) AS Questions, 
           COALESCE(PostStats.Answers, 0) AS Answers,
           COALESCE(PostStats.TotalScore, 0) AS TotalScore, 
           COALESCE(UserBadges.BadgeCount, 0) AS BadgeCount, 
           COALESCE(UserBadges.GoldBadges, 0) AS GoldBadges, 
           COALESCE(UserBadges.SilverBadges, 0) AS SilverBadges, 
           COALESCE(UserBadges.BronzeBadges, 0) AS BronzeBadges 
    FROM Users U
    LEFT JOIN PostStatistics PostStats ON U.Id = PostStats.OwnerUserId
    LEFT JOIN UserBadges UserBadges ON U.Id = UserBadges.UserId
)
SELECT UserId, DisplayName, Reputation, Views, TotalPosts, Questions, Answers, TotalScore, 
       BadgeCount, GoldBadges, SilverBadges, BronzeBadges
FROM UserEngagement
WHERE Reputation > 1000
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 100;
