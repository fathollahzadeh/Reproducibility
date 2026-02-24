WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC, ub.BadgeCount DESC) AS UserRank
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.TotalScore,
    ru.AvgViewCount,
    ru.BadgeCount,
    CASE 
        WHEN ru.BadgeCount > 10 THEN 'High Achiever'
        WHEN ru.BadgeCount BETWEEN 5 AND 10 THEN 'Achiever'
        ELSE 'Novice'
    END AS AchievementLevel
FROM 
    RankedUsers ru
WHERE 
    ru.AnswerCount > 0
ORDER BY 
    ru.UserRank
LIMIT 100;
