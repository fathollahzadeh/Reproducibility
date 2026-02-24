WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeStats AS (
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
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.AcceptedAnswerCount,
        ubs.BadgeCount,
        ubs.GoldBadgeCount,
        ubs.SilverBadgeCount,
        ubs.BronzeBadgeCount
    FROM 
        UserPostStats ups
    LEFT JOIN 
        UserBadgeStats ubs ON ups.UserId = ubs.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    CombinedStats
ORDER BY 
    PostCount DESC, 
    BadgeCount DESC;