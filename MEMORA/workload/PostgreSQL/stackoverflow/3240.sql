WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges 
    GROUP BY 
        UserId
), 
UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600, 0)) AS AvgHourToActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(up.QuestionCount, 0) AS QuestionCount,
        COALESCE(up.AnswerCount, 0) AS AnswerCount,
        COALESCE(up.TotalScore, 0) AS TotalScore,
        COALESCE(up.TotalViews, 0) AS TotalViews,
        COALESCE(up.AvgHourToActivity, 0) AS AvgHourToActivity,
        RANK() OVER(ORDER BY COALESCE(up.TotalScore, 0) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserPosts up ON u.Id = up.OwnerUserId
)
SELECT 
    ru.DisplayName,
    ru.BadgeCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.TotalScore,
    ru.TotalViews,
    ru.AvgHourToActivity,
    CASE 
        WHEN ru.BadgeCount >= 10 THEN 'Expert'
        WHEN ru.BadgeCount >= 5 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel,
    CASE 
        WHEN ru.AvgHourToActivity < 1 THEN 'Very Active'
        WHEN ru.AvgHourToActivity < 24 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    RankedUsers ru
WHERE 
    ru.ScoreRank <= 10
ORDER BY 
    ru.TotalScore DESC;
