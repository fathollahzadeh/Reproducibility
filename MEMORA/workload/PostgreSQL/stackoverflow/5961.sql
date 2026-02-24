WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(p.PostCount, 0) AS PostCount,
        COALESCE(p.QuestionCount, 0) AS QuestionCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.PositiveScoreCount, 0) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        TopPosts p ON u.Id = p.OwnerUserId
)
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.BadgeCount,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.PositiveScoreCount
FROM 
    UserStats u
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    u.BadgeCount DESC
LIMIT 50;
