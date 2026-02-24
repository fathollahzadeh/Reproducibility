WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadgeCounts AS (
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
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UPC.QuestionsCount, 0) AS TotalQuestions,
    COALESCE(UPC.AnswersCount, 0) AS TotalAnswers,
    COALESCE(UBC.BadgeCount, 0) AS TotalBadges,
    COALESCE(UBC.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadgeCount, 0) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    UserPostCounts UPC ON u.Id = UPC.UserId
LEFT JOIN 
    UserBadgeCounts UBC ON u.Id = UBC.UserId
ORDER BY 
    u.Reputation DESC
LIMIT 100;