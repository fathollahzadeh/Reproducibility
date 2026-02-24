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
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AverageViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        b.GoldBadges,
        b.SilverBadges,
        b.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.LastActivityDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentRank
    FROM 
        Posts p
)
SELECT 
    au.DisplayName,
    au.PostCount,
    au.BadgeCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    ARRAY_AGG(rp.Title) AS RecentPostTitles
FROM 
    ActiveUsers au
LEFT JOIN 
    RecentPosts rp ON au.Id = rp.OwnerUserId AND rp.RecentRank <= 3
GROUP BY 
    au.DisplayName, au.PostCount, au.BadgeCount, au.GoldBadges, au.SilverBadges, au.BronzeBadges
ORDER BY 
    au.BadgeCount DESC, 
    au.PostCount DESC;