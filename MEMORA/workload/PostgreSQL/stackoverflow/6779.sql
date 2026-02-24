WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        QuestionPosts,
        AnswerPosts,
        TotalScore
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 10 AND TotalScore > 50
),
TopBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1  
    GROUP BY 
        UserId
),
UserRanking AS (
    SELECT 
        au.UserId,
        au.TotalPosts,
        au.QuestionPosts,
        au.AnswerPosts,
        au.TotalScore,
        COALESCE(tb.BadgeCount, 0) AS GoldBadges
    FROM 
        ActiveUsers au
    LEFT JOIN 
        TopBadges tb ON au.UserId = tb.UserId
),
RankedUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        QuestionPosts,
        AnswerPosts,
        TotalScore,
        GoldBadges,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS UserRank
    FROM 
        UserRanking
)
SELECT 
    u.DisplayName,
    ru.TotalPosts,
    ru.QuestionPosts,
    ru.AnswerPosts,
    ru.TotalScore,
    ru.GoldBadges,
    ru.UserRank
FROM 
    RankedUsers ru
JOIN 
    Users u ON ru.UserId = u.Id
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank, ru.TotalScore DESC;