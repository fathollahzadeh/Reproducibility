
WITH UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(Posts.Score) AS TotalScore,
        AVG(Posts.ViewCount) AS AvgViews
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
BadgeStatistics AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalStatistics AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.TotalPosts,
        Us.TotalQuestions,
        Us.TotalAnswers,
        Us.TotalScore,
        Us.AvgViews,
        COALESCE(Bs.TotalBadges, 0) AS TotalBadges,
        COALESCE(Bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(Bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(Bs.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStatistics Us
    LEFT JOIN 
        BadgeStatistics Bs ON Us.UserId = Bs.UserId
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    AvgViews,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalStatistics
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
