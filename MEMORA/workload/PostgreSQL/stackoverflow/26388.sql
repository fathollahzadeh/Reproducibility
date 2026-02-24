WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStat AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalViews,
        us.AverageScore,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    LEFT JOIN 
        PostStat us ON u.Id = us.OwnerUserId
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.CreationDate,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.AverageScore,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ub.TotalBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeStats ub ON ups.UserId = ub.UserId
WHERE 
    ups.Reputation > 1000
ORDER BY 
    ups.TotalViews DESC, ups.TotalPosts DESC, ups.DisplayName ASC
LIMIT 10;
