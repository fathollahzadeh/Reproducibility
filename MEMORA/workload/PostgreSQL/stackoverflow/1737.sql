WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UsersWithPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalPosts, 0) DESC, COALESCE(bs.BadgeCount, 0) DESC) AS Rank
    FROM Users u
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges bs ON u.Id = bs.UserId
)
SELECT 
    uwp.UserId,
    uwp.DisplayName,
    uwp.TotalPosts,
    uwp.BadgeCount,
    COALESCE(ps.TotalScore, 0) AS TotalPostScore,
    ps.AvgViewCount,
    CASE 
        WHEN uwp.TotalPosts > 100 THEN 'Veteran'
        WHEN uwp.BadgeCount > 50 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel
FROM UsersWithPosts uwp
LEFT JOIN PostStatistics ps ON uwp.UserId = ps.OwnerUserId
WHERE uwp.TotalPosts > 0
ORDER BY uwp.Rank
LIMIT 10;