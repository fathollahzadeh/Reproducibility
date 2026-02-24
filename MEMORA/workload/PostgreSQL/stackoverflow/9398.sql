WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, 
           COUNT(P.Id) AS PostsCount, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT UserId, Reputation, PostsCount, QuestionsCount, AnswersCount, 
           GoldBadges, SilverBadges, BronzeBadges,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
)
SELECT TU.UserId, U.DisplayName, TU.Reputation, TU.PostsCount, 
       TU.QuestionsCount, TU.AnswersCount, 
       TU.GoldBadges + TU.SilverBadges + TU.BronzeBadges AS TotalBadges
FROM TopUsers TU
JOIN Users U ON TU.UserId = U.Id
WHERE TU.Rank <= 10
ORDER BY TU.Reputation DESC;
