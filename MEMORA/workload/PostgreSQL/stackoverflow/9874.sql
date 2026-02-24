WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        ps.AverageScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    COALESCE(up.BadgeCount, 0) AS TotalBadges,
    COALESCE(up.GoldBadges, 0) AS GoldBadges,
    COALESCE(up.SilverBadges, 0) AS SilverBadges,
    COALESCE(up.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    COALESCE(up.Questions, 0) AS TotalQuestions,
    COALESCE(up.Answers, 0) AS TotalAnswers,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(up.AverageScore, 0) AS AverageScore
FROM 
    UserPerformance up
ORDER BY 
    TotalViews DESC, 
    AverageScore DESC
LIMIT 100;
