WITH UserBadgeStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT Tags) AS UniqueTagsUsed
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(p.TotalPosts, 0) AS TotalPosts,
        COALESCE(p.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(p.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(p.UniqueTagsUsed, 0) AS UniqueTagsUsed,
        ROW_NUMBER() OVER (ORDER BY COALESCE(p.TotalPosts, 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats b ON u.Id = b.UserId
    LEFT JOIN 
        PostStats p ON u.Id = p.OwnerUserId
),
UserCounts AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    m.Id,
    m.DisplayName,
    m.GoldBadges,
    m.SilverBadges,
    m.BronzeBadges,
    m.TotalPosts,
    m.TotalQuestions,
    m.TotalAnswers,
    m.UniqueTagsUsed,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN m.TotalQuestions > 0 THEN ROUND(CAST(m.TotalAnswers AS DECIMAL) / NULLIF(m.TotalQuestions, 0), 2)
        ELSE NULL 
    END AS AnswerToQuestionRatio
FROM 
    MostActiveUsers m
LEFT JOIN 
    UserCounts c ON m.Id = c.Id
WHERE 
    m.UserRank <= 10
ORDER BY 
    m.UserRank;
