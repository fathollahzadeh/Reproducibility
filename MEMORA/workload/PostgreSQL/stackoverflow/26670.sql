
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewPostCount
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
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.WikiCount,
        ups.HighViewPostCount,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserPostStats ups
    LEFT JOIN 
        UserBadges ub ON ups.UserId = ub.UserId
)
SELECT 
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount,
    HighViewPostCount,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    (QuestionCount + AnswerCount + WikiCount) AS TotalPosts,
    (CASE WHEN PostCount = 0 THEN 0 ELSE (HighViewPostCount * 100.0 / PostCount) END) AS HighViewPostPercentage
FROM 
    CombinedStats
WHERE 
    (QuestionCount + AnswerCount + WikiCount) > 5 
ORDER BY 
    HighViewPostPercentage DESC, TotalPosts DESC;
