WITH UserBadges AS (
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
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.TotalPosts, 0) AS TotalPosts,
        COALESCE(pb.Questions, 0) AS Questions,
        COALESCE(pb.Answers, 0) AS Answers,
        COALESCE(pb.TotalScore, 0) AS TotalScore,
        COALESCE(pb.TotalViews, 0) AS TotalViews,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStats pb ON u.Id = pb.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    Questions, 
    Answers, 
    TotalScore, 
    TotalViews,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    CombinedStats
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalScore DESC, 
    BadgeCount DESC
LIMIT 10;
