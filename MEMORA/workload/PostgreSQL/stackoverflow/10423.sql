WITH UserPostStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
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
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(bb.BadgeCount, 0) AS BadgeCount,
    COALESCE(bb.GoldBadges, 0) AS GoldBadges,
    COALESCE(bb.SilverBadges, 0) AS SilverBadges,
    COALESCE(bb.BronzeBadges, 0) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserPostStatistics ps ON u.Id = ps.UserId
LEFT JOIN 
    UserBadges bb ON u.Id = bb.UserId
ORDER BY 
    TotalScore DESC, PostCount DESC;