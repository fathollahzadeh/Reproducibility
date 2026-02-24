WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS TotalBadges,
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
RecentPosts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS RecentPostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1' month
    GROUP BY 
        p.OwnerUserId
),
UsersWithActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
        COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
        COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(rp.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(rp.AvgScore, 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
)
SELECT 
    uwa.UserId,
    uwa.DisplayName,
    uwa.TotalBadges,
    uwa.GoldBadges,
    uwa.SilverBadges,
    uwa.BronzeBadges,
    uwa.RecentPostCount,
    uwa.AvgScore,
    CASE 
        WHEN uwa.TotalBadges >= 10 THEN 'Expert'
        WHEN uwa.AvgScore > 50 THEN 'Active Contributor'
        ELSE 'Novice'
    END AS UserStatus
FROM 
    UsersWithActivity uwa
WHERE 
    uwa.RecentPostCount > 0
ORDER BY 
    uwa.TotalBadges DESC, uwa.AvgScore DESC;