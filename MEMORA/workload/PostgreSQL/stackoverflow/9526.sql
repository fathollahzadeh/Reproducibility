WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount,
        up.PostCount,
        up.TotalScore,
        up.AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        ActiveUserPosts up ON u.Id = up.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    COALESCE(ua.BadgeCount, 0) AS BadgeCount,
    COALESCE(ua.GoldCount, 0) AS GoldCount,
    COALESCE(ua.SilverCount, 0) AS SilverCount,
    COALESCE(ua.BronzeCount, 0) AS BronzeCount,
    COALESCE(ua.PostCount, 0) AS PostCount,
    COALESCE(ua.TotalScore, 0) AS TotalScore,
    COALESCE(ua.AvgViewCount, 0) AS AvgViewCount
FROM 
    UserActivity ua
ORDER BY 
    ua.TotalScore DESC, 
    ua.BadgeCount DESC
LIMIT 100;