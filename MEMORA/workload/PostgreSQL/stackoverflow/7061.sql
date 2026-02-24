
WITH UserReputation AS (
    SELECT U.Id, U.DisplayName, U.Reputation, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions, 
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT UR.Id AS UserId, UR.DisplayName, UR.Reputation, 
           COALESCE(PS.TotalPosts, 0) AS TotalPosts,
           COALESCE(PS.Questions, 0) AS Questions,
           COALESCE(PS.Answers, 0) AS Answers,
           UR.GoldBadges, UR.SilverBadges, UR.BronzeBadges, 
           PS.AvgScore
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.Id = PS.OwnerUserId
)
SELECT UserId, DisplayName, Reputation, TotalPosts, Questions, Answers,
       GoldBadges, SilverBadges, BronzeBadges, AvgScore
FROM CombinedStats
WHERE Reputation > 1000
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 50;
