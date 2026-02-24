WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestionCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        AcceptedQuestionCount,
        TotalQuestionScore,
        TotalAnswerScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalQuestionScore DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.AnswerCount,
    u.AcceptedQuestionCount,
    u.TotalQuestionScore,
    u.TotalAnswerScore,
    COALESCE(badge_count.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers u
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) badge_count ON u.UserId = badge_count.UserId
WHERE 
    u.Rank <= 10
ORDER BY 
    u.Rank;
