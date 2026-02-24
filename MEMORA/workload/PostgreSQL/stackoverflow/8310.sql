WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
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
        SUM(p.Score) AS TotalScore
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
        COALESCE(ubs.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(ubs.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(ubs.BronzeBadgeCount, 0) AS BronzeBadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore
FROM 
    UserPerformance
WHERE 
    TotalScore > 20 OR BadgeCount >= 5
ORDER BY 
    TotalScore DESC, BadgeCount DESC
LIMIT 10;
