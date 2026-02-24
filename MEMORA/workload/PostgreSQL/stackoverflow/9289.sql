
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
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
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
BadgeStatistics AS (
    SELECT 
        AUD.UserId,
        AUD.BadgeCount,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.TotalViews,
        PS.AverageScore,
        CASE 
            WHEN AUD.BadgeCount >= 5 THEN 'High Achiever'
            WHEN AUD.BadgeCount BETWEEN 3 AND 4 THEN 'Moderate Achiever'
            ELSE 'Novice'
        END AS AchievementLevel
    FROM UserBadges AUD
    JOIN PostStatistics PS ON AUD.UserId = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    BS.BadgeCount,
    BS.TotalPosts,
    BS.TotalQuestions,
    BS.TotalAnswers,
    BS.TotalViews,
    BS.AverageScore,
    BS.AchievementLevel
FROM BadgeStatistics BS
JOIN Users U ON BS.UserId = U.Id
WHERE BS.TotalPosts > 10
ORDER BY BS.TotalViews DESC, BS.BadgeCount DESC;
