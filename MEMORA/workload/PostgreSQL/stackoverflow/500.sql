WITH UserBadges AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation,
           COALESCE(ub.GoldBadges, 0) AS GoldBadges,
           COALESCE(ub.SilverBadges, 0) AS SilverBadges,
           COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
           COALESCE(ps.CommentCount, 0) AS TotalComments,
           COALESCE(ps.TotalScore, 0) AS TotalScore,
           COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
           COALESCE(ps.AnswerCount, 0) AS TotalAnswers
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
RankedUsers AS (
    SELECT UserId, 
           DisplayName, 
           Reputation,
           GoldBadges, 
           SilverBadges, 
           BronzeBadges,
           TotalComments, 
           TotalScore, 
           TotalQuestions, 
           TotalAnswers,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS UserRank
    FROM UserReputation
)
SELECT UserId, 
       DisplayName, 
       Reputation, 
       GoldBadges, 
       SilverBadges, 
       BronzeBadges, 
       TotalComments, 
       TotalScore, 
       TotalQuestions, 
       TotalAnswers
FROM RankedUsers
WHERE UserRank <= 10
ORDER BY UserRank;
