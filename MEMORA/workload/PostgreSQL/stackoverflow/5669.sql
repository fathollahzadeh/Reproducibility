WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubs.BadgeCount, 0) AS BadgeCount,
        COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
        COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
        COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.AvgScore, 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    up.AvgScore
FROM 
    UserPerformance up
WHERE 
    up.PostCount > 0
ORDER BY 
    up.AvgScore DESC, up.BadgeCount DESC
LIMIT 10;
