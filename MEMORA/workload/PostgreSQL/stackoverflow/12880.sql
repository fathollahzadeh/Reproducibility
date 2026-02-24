WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
UserBadgeStats AS (
    SELECT 
        UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        UserId
)
SELECT 
    ups.UserId,
    ups.Reputation,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ubs.BadgeCount,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeStats ubs ON ups.UserId = ubs.UserId
ORDER BY 
    ups.Reputation DESC, ups.PostCount DESC;