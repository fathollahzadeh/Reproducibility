WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(b.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(b.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    UserPostCounts u
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
ORDER BY 
    u.Reputation DESC, 
    u.PostCount DESC;