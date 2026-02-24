WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.QuestionCount, 0) AS TotalQuestions,
    COALESCE(up.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadgeCount, 0) AS TotalGoldBadges,
    COALESCE(ub.SilverBadgeCount, 0) AS TotalSilverBadges,
    COALESCE(ub.BronzeBadgeCount, 0) AS TotalBronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserPostCounts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    u.Reputation DESC
LIMIT 100;