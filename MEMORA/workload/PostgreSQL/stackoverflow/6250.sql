WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), 
PostStats AS (
    SELECT OwnerUserId, 
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount, 
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews,
           SUM(CASE WHEN CommentCount > 0 THEN 1 END) AS PostedCommentCount,
           SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
UserBadgeCounts AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges, 
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges, 
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT U.DisplayName, 
       U.Reputation, 
       UR.Rank, 
       COALESCE(PS.QuestionCount, 0) AS QuestionCount, 
       COALESCE(PS.AnswerCount, 0) AS AnswerCount, 
       COALESCE(PS.TotalViews, 0) AS TotalViews, 
       COALESCE(PS.PostedCommentCount, 0) AS PostedCommentCount, 
       COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
       COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
       COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
       PS.TotalScore
FROM Users U
JOIN UserReputation UR ON U.Id = UR.Id
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
ORDER BY U.Reputation DESC, U.DisplayName ASC
LIMIT 50;
