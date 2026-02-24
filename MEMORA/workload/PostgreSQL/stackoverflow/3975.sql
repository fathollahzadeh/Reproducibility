
WITH UserBadgeCounts AS (
    SELECT UserId,
           COUNT(*) FILTER (WHERE Class = 1) AS GoldCount,
           COUNT(*) FILTER (WHERE Class = 2) AS SilverCount,
           COUNT(*) FILTER (WHERE Class = 3) AS BronzeCount
    FROM Badges
    GROUP BY UserId
), 
PostStats AS (
    SELECT OwnerUserId,
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews
    FROM Posts
    GROUP BY OwnerUserId
),
UserAggregate AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(ub.GoldCount, 0) AS GoldBadges,
           COALESCE(ub.SilverCount, 0) AS SilverBadges,
           COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
           COALESCE(ps.TotalPosts, 0) AS TotalPosts,
           COALESCE(ps.QuestionCount, 0) AS QuestionCount,
           COALESCE(ps.AnswerCount, 0) AS AnswerCount,
           COALESCE(ps.TotalViews, 0) AS TotalViews,
           RANK() OVER (ORDER BY COALESCE(ps.TotalPosts, 0) DESC, u.Reputation DESC) AS PostRank,
           u.Reputation
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT UserId,
       DisplayName,
       GoldBadges,
       SilverBadges,
       BronzeBadges,
       TotalPosts,
       QuestionCount,
       AnswerCount,
       TotalViews,
       PostRank,
       CASE WHEN TotalPosts = 0 THEN 'No Posts' 
            WHEN QuestionCount > AnswerCount THEN 'More Questions than Answers' 
            ELSE 'More Answers than Questions' END AS PostBalance,
       (SELECT COUNT(DISTINCT c.PostId) 
        FROM Comments c 
        WHERE c.UserId = UserId) AS TotalComments
FROM UserAggregate
WHERE Reputation > 1000
ORDER BY TotalViews DESC, PostRank
LIMIT 50;
