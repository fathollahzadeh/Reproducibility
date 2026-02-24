WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ap.PostCount, 0) AS TotalPosts,
        COALESCE(ap.PositiveScores, 0) AS PositiveScores,
        COALESCE(ap.AvgViewCount, 0) AS AverageViewCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN ActivePosts ap ON u.Id = ap.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalBadges,
    ua.TotalPosts,
    ua.PositiveScores,
    ua.AverageViewCount
FROM UserActivity ua
WHERE ua.TotalPosts > 0
ORDER BY ua.TotalBadges DESC, ua.PositiveScores DESC, ua.AverageViewCount DESC
LIMIT 10;