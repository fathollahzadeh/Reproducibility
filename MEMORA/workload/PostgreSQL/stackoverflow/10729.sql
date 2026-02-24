WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TotalPosts, 
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.TotalViews,
    PS.TotalScore
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
ORDER BY U.Reputation DESC, PS.TotalScore DESC;