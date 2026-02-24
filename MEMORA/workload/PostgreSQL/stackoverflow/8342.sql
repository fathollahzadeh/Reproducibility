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
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ub.UserId,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ps.LastPostDate
    FROM 
        UserBadges ub
    FULL OUTER JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    u.DisplayName,
    up.PostCount,
    up.TotalScore,
    up.AvgViewCount,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.LastPostDate
FROM 
    Users u
JOIN 
    UserPerformance up ON u.Id = up.UserId
WHERE 
    up.PostCount > 0
ORDER BY 
    up.TotalScore DESC, up.PostCount DESC
LIMIT 10;
