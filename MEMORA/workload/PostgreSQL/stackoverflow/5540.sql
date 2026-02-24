WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT p.Tags) AS UniqueTagsCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ubc.UserId,
    ubc.DisplayName,
    ubc.BadgeCount,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.UniqueTagsCount, 0) AS UniqueTagsCount,
    (ubc.BadgeCount + COALESCE(ps.TotalPosts, 0)) AS PerformanceScore
FROM 
    UserBadgeCounts ubc
LEFT JOIN 
    PostStats ps ON ubc.UserId = ps.OwnerUserId
ORDER BY 
    PerformanceScore DESC
LIMIT 10;
