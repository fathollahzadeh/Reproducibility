WITH UserBadges AS (
    SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount, SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS PostCount, SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, U.LastAccessDate, 
           COALESCE(UB.BadgeCount, 0) AS BadgeCount, COALESCE(PS.PostCount, 0) AS PostCount,
           COALESCE(PS.QuestionCount, 0) AS QuestionCount, COALESCE(PS.AnswerCount, 0) AS AnswerCount,
           COALESCE(PS.TotalViews, 0) AS TotalViews, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT U.UserId, U.DisplayName, U.Reputation, U.LastAccessDate, U.BadgeCount,
       U.PostCount, U.QuestionCount, U.AnswerCount, U.TotalViews, 
       U.GoldBadges, U.SilverBadges, U.BronzeBadges
FROM UserActivity U
WHERE (U.Reputation > 100 OR U.BadgeCount > 0)
ORDER BY U.Reputation DESC, U.PostCount DESC
LIMIT 50;
