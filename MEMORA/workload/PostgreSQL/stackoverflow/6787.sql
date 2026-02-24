WITH UserBadgeStats AS (
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
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(pb.PostCount, 0) AS PostCount,
        COALESCE(pb.TotalViews, 0) AS TotalViews,
        COALESCE(pb.AverageScore, 0) AS AverageScore,
        COALESCE(pb.TotalComments, 0) AS TotalComments,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges
    FROM 
        UserBadgeStats u
    LEFT JOIN 
        PostStats pb ON u.UserId = pb.OwnerUserId
)
SELECT 
    cs.DisplayName,
    cs.PostCount,
    cs.TotalViews,
    cs.AverageScore,
    cs.TotalComments,
    cs.BadgeCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges
FROM 
    CombinedStats cs
ORDER BY 
    cs.PostCount DESC, cs.TotalViews DESC;
