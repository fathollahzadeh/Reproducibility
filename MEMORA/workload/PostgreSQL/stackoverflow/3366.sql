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
PostAnalytics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(pb.PostCount, 0) AS PostCount,
        COALESCE(pb.AvgScore, 0) AS AvgScore,
        COALESCE(pb.TotalViews, 0) AS TotalViews,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY COALESCE(pb.PostCount, 0) DESC, COALESCE(pb.AvgScore, 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        PostAnalytics pb ON u.Id = pb.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    u.Id,
    u.DisplayName,
    ue.PostCount,
    ue.AvgScore,
    ue.TotalViews,
    ue.BadgeCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges,
    CASE 
        WHEN ue.PostCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    UserEngagement ue
JOIN 
    Users u ON ue.UserId = u.Id
WHERE 
    (ue.TotalViews >= 1000 OR ue.BadgeCount > 2) 
AND 
    ue.Rank <= 10
ORDER BY 
    ue.Rank;
