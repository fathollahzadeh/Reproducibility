
WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserAchievements AS (
    SELECT 
        U.DisplayName,
        COALESCE(P.QuestionCount, 0) AS QuestionCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN PostStatistics P ON U.Id = P.OwnerUserId
    LEFT JOIN UserBadgeStats B ON U.Id = B.UserId
)
SELECT 
    UA.DisplayName,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalViews,
    UA.TotalScore,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    RANK() OVER (ORDER BY UA.TotalScore DESC) AS ScoreRank
FROM UserAchievements UA
WHERE UA.BadgeCount > 0
ORDER BY UA.TotalScore DESC, UA.DisplayName ASC
LIMIT 10;
