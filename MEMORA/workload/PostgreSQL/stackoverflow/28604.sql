WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BC.TotalBadges, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS PostCount,
        COALESCE(PS.TotalQuestions, 0) AS QuestionCount,
        COALESCE(PS.TotalAnswers, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS ViewCount,
        COALESCE(PS.TotalScore, 0) AS Score
    FROM Users U
    LEFT JOIN UserBadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.BadgeCount,
    UP.PostCount,
    UP.QuestionCount,
    UP.AnswerCount,
    UP.ViewCount,
    UP.Score
FROM UserPerformance UP
WHERE UP.BadgeCount > 0 OR UP.PostCount > 0
ORDER BY UP.BadgeCount DESC, UP.ViewCount DESC, UP.Score DESC
LIMIT 10;
