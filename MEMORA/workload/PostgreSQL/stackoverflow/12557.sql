WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadgeStats AS (
    SELECT 
        UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    ups.PostCount,
    ups.TotalPostScore,
    ups.TotalViewCount,
    ups.AvgPostScore,
    ups.AvgViewCount,
    ubs.BadgeCount,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN 
    UserBadgeStats ubs ON u.Id = ubs.UserId
ORDER BY 
    ups.TotalPostScore DESC, ups.PostCount DESC;