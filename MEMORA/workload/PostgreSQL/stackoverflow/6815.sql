
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopBadges AS (
    SELECT 
        B.UserId,
        B.Name AS BadgeName,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId, B.Name
),
UserBadgeStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.TotalWikis,
        U.TotalViews,
        U.TotalScore,
        COALESCE(SUM(UB.BadgeCount), 0) AS TotalBadges
    FROM UserStats U
    LEFT JOIN TopBadges UB ON U.UserId = UB.UserId
    GROUP BY U.UserId, U.DisplayName, U.Reputation, U.TotalPosts, U.TotalQuestions, U.TotalAnswers, U.TotalWikis, U.TotalViews, U.TotalScore
)
SELECT 
    UserBadgeStats.*,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = UserBadgeStats.UserId) AS TotalComments
FROM UserBadgeStats
ORDER BY UserBadgeStats.Reputation DESC, UserBadgeStats.TotalPosts DESC
LIMIT 10;
