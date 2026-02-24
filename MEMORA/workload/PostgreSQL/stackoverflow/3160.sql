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
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(ps.LastPostDate, '1970-01-01') AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
WHERE 
    (ub.BadgeCount IS NULL OR ub.BadgeCount >= 1) 
    AND (ps.PostCount IS NOT NULL AND ps.PostCount > 0)
ORDER BY 
    TotalScore DESC, BadgeCount DESC
LIMIT 100;
