
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.AvgQuestionScore,
    ups.TotalAnswers,
    COALESCE(ubc.TotalBadges, 0) AS TotalBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeCounts ubc ON ups.UserId = ubc.UserId
ORDER BY 
    ups.AvgQuestionScore DESC, 
    ups.TotalAnswers DESC;
