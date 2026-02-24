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
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pc.TotalPosts, 0) AS TotalPosts,
        COALESCE(pc.Questions, 0) AS Questions,
        COALESCE(pc.Answers, 0) AS Answers,
        COALESCE(pc.TotalViews, 0) AS TotalViews,
        COALESCE(pc.AverageScore, 0.0) AS AverageScore,
        COALESCE(bc.BadgeCount, 0) AS TotalBadges,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStats pc ON u.Id = pc.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    AverageScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    CombinedStats
WHERE 
    TotalPosts > 0 OR TotalBadges > 0
ORDER BY 
    TotalPosts DESC, TotalBadges DESC;
