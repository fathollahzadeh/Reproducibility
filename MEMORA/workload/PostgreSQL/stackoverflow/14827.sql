WITH UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.CommentCount, 0)) AS AvgCommentsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeMetrics AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    upm.UserId,
    upm.DisplayName,
    upm.TotalPosts,
    upm.TotalQuestions,
    upm.TotalAnswers,
    upm.TotalAcceptedAnswers,
    upm.TotalViews,
    upm.TotalScore,
    upm.AvgCommentsPerPost,
    COALESCE(ubm.TotalBadges, 0) AS TotalBadges,
    COALESCE(ubm.TotalGoldBadges, 0) AS TotalGoldBadges,
    COALESCE(ubm.TotalSilverBadges, 0) AS TotalSilverBadges,
    COALESCE(ubm.TotalBronzeBadges, 0) AS TotalBronzeBadges
FROM 
    UserPostMetrics upm
LEFT JOIN 
    UserBadgeMetrics ubm ON upm.UserId = ubm.UserId
ORDER BY 
    upm.TotalPosts DESC;