WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(Id) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViews,
    UPS.AverageScore,
    COALESCE(UBC.TotalBadges, 0) AS TotalBadges
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadgeCount UBC ON UPS.UserId = UBC.UserId
ORDER BY 
    UPS.TotalPosts DESC
LIMIT 100;