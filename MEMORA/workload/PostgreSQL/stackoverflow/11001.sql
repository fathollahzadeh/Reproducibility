WITH UserPosts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.PostTypeId, 
        COUNT(*) AS TotalPosts, 
        AVG(p.ViewCount) AS AvgViewCount, 
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    up.TotalScore,
    up.AvgViewCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ps.PostTypeId,
    ps.TotalPosts,
    ps.AvgViewCount AS PostAvgViewCount,
    ps.AvgScore AS PostAvgScore
FROM 
    UserPosts up
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN 
    PostStatistics ps ON true
ORDER BY 
    up.TotalScore DESC, 
    up.PostCount DESC;