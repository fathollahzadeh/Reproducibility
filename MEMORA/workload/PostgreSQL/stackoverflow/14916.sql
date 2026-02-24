WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(Posts.Score) AS TotalScore,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AveragePostScore,
        AVG(Posts.ViewCount) AS AveragePostViewCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
BadgeStats AS (
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
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.QuestionsCount,
    U.AnswersCount,
    U.TotalScore,
    U.TotalViews,
    U.AveragePostScore,
    U.AveragePostViewCount,
    COALESCE(B.TotalBadges, 0) AS TotalBadges,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStats U
LEFT JOIN 
    BadgeStats B ON U.UserId = B.UserId
ORDER BY 
    U.TotalScore DESC, U.TotalPosts DESC;