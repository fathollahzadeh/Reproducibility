WITH UserBadges AS (
    SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount, SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), PostsStats AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions, 
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(P.ViewCount) AS TotalViews, AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserProfile AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, 
           PS.TotalPosts, PS.Questions, PS.Answers, PS.TotalViews, PS.AverageScore, U.CreationDate
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    JOIN PostsStats PS ON U.Id = PS.OwnerUserId
)
SELECT UP.DisplayName, UP.Reputation, UP.BadgeCount, UP.GoldBadges, UP.SilverBadges, UP.BronzeBadges,
       UP.TotalPosts, UP.Questions, UP.Answers, UP.TotalViews, UP.AverageScore, UP.CreationDate
FROM UserProfile UP
WHERE UP.Reputation > 1000
ORDER BY UP.Reputation DESC, UP.TotalPosts DESC
LIMIT 100;
