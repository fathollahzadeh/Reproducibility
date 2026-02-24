WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
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
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UPC.QuestionCount, 0) AS TotalQuestions,
    COALESCE(UPC.AnswerCount, 0) AS TotalAnswers,
    COALESCE(UBC.BadgeCount, 0) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    UserPostCounts UPC ON u.Id = UPC.UserId
LEFT JOIN 
    UserBadgeCounts UBC ON u.Id = UBC.UserId
ORDER BY 
    u.Reputation DESC
LIMIT 100;