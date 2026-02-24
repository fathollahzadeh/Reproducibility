
WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           COUNT(DISTINCT P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN P.PostTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosedPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostsWithTags AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.ViewCount, 
           P.CreationDate, 
           T.TagName
    FROM Posts P
    JOIN Tags T ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
),
UserBadges AS (
    SELECT U.Id AS UserId,
           COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)

SELECT UR.UserId, 
       UR.DisplayName, 
       UR.Reputation, 
       UR.TotalPosts, 
       UR.QuestionCount, 
       UR.AnswerCount, 
       UR.ClosedPosts, 
       UB.BadgeCount, 
       UB.GoldBadges, 
       UB.SilverBadges, 
       UB.BronzeBadges, 
       COUNT(DISTINCT PWT.PostId) AS RelatedPostsCount,
       SUM(PWT.ViewCount) AS TotalViewCount,
       MIN(PWT.CreationDate) AS FirstPostDate
FROM UserReputation UR
JOIN UserBadges UB ON UR.UserId = UB.UserId
LEFT JOIN PostsWithTags PWT ON UR.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PWT.PostId)
WHERE UR.Reputation > 1000
GROUP BY UR.UserId, UR.DisplayName, UR.Reputation, UR.TotalPosts, UR.QuestionCount, UR.AnswerCount, UR.ClosedPosts, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
ORDER BY UR.Reputation DESC, UR.TotalPosts DESC;
