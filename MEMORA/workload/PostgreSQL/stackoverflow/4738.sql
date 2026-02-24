WITH UserBadgeCounts AS (
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
        COUNT(1) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        ubc.UserId,
        ubc.DisplayName,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.AverageScore,
        ubc.BadgeCount,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges
    FROM 
        UserBadgeCounts ubc
    JOIN 
        PostStatistics ps ON ubc.UserId = ps.OwnerUserId
)
SELECT 
    upbs.DisplayName,
    COALESCE(upbs.TotalPosts, 0) AS TotalPosts,
    COALESCE(upbs.Questions, 0) AS Questions,
    COALESCE(upbs.Answers, 0) AS Answers,
    COALESCE(upbs.AverageScore, 0) AS AverageScore,
    COALESCE(upbs.BadgeCount, 0) AS BadgeCount,
    COALESCE(upbs.GoldBadges, 0) AS GoldBadges,
    COALESCE(upbs.SilverBadges, 0) AS SilverBadges,
    COALESCE(upbs.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN upbs.BadgeCount > 10 AND upbs.AverageScore > 50 THEN 'High Engagement'
        WHEN upbs.BadgeCount BETWEEN 5 AND 10 AND upbs.AverageScore BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM 
    UserBadgeCounts ubc
FULL OUTER JOIN 
    UserPostBadgeStats upbs ON ubc.UserId = upbs.UserId
WHERE 
    ubc.BadgeCount IS NOT NULL OR upbs.TotalPosts IS NOT NULL
ORDER BY 
    BadgeCount DESC, AverageScore DESC;
