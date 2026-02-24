
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivitySummary AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.BadgeCount,
        um.GoldBadges,
        um.SilverBadges,
        um.BronzeBadges,
        COALESCE(asum.TotalPosts, 0) AS TotalPosts,
        COALESCE(asum.TotalViews, 0) AS TotalViews,
        COALESCE(asum.TotalScore, 0) AS TotalScore
    FROM 
        UserMetrics um
    LEFT JOIN 
        ActivitySummary asum ON um.UserId = asum.UserId
)
SELECT 
    up.DisplayName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.TotalPosts,
    up.TotalViews,
    up.TotalScore,
    RANK() OVER (ORDER BY up.TotalScore DESC, up.TotalPosts DESC) AS UserRank
FROM 
    UserPerformance up
WHERE 
    (up.TotalPosts > 5 OR up.BadgeCount > 0)
ORDER BY 
    UserRank
FETCH FIRST 10 ROWS ONLY;
