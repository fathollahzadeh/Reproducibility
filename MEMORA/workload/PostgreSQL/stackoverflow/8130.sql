WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
UserPosts AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount, SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, AVG(Score) AS AvgPostScore
    FROM Posts
    GROUP BY OwnerUserId
),
CombinedStats AS (
    SELECT U.Id AS UserId, U.DisplayName, COALESCE(UB.BadgeCount, 0) AS BadgeCount,
           COALESCE(UB.GoldBadges, 0) AS GoldBadges, COALESCE(UB.SilverBadges, 0) AS SilverBadges,
           COALESCE(UB.BronzeBadges, 0) AS BronzeBadges, COALESCE(UP.PostCount, 0) AS PostCount,
           COALESCE(UP.QuestionCount, 0) AS QuestionCount, COALESCE(UP.AnswerCount, 0) AS AnswerCount,
           COALESCE(UP.AvgPostScore, 0) AS AvgPostScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UserPosts UP ON U.Id = UP.OwnerUserId
)
SELECT UserId, DisplayName, BadgeCount, GoldBadges, SilverBadges, BronzeBadges, 
       PostCount, QuestionCount, AnswerCount, AvgPostScore
FROM CombinedStats
WHERE PostCount > 10
ORDER BY AvgPostScore DESC
LIMIT 50;
