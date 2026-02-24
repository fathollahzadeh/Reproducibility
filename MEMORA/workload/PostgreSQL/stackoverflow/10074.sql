WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        MAX(Reputation) AS MaxReputation,
        MIN(Reputation) AS MinReputation,
        COUNT(CASE WHEN LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' THEN 1 END) AS ActiveUsers
    FROM 
        Users
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(Score) AS AveragePostScore,
        MAX(ViewCount) AS MaxViews,
        MIN(ViewCount) AS MinViews
    FROM 
        Posts
),
BadgeStats AS (
    SELECT 
        COUNT(*) AS TotalBadges,
        COUNT(DISTINCT UserId) AS UsersWithBadges,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
)
SELECT 
    u.TotalUsers,
    u.AverageReputation,
    u.MaxReputation,
    u.MinReputation,
    u.ActiveUsers,
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    p.AveragePostScore,
    p.MaxViews,
    p.MinViews,
    b.TotalBadges,
    b.UsersWithBadges,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges
FROM 
    UserStats u, PostStats p, BadgeStats b;