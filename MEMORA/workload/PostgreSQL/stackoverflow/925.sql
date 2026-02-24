
WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 1000
    GROUP BY p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ps.QuestionCount, 
    ps.AnswerCount,
    ps.TotalScore,
    ps.TotalViews,
    ra.LastActivityDate
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentActivity ra ON u.Id = ra.OwnerUserId
WHERE (ps.QuestionCount > 5 OR ps.AnswerCount > 10)
AND ra.LastActivityDate > CURRENT_DATE - INTERVAL '6 months'
ORDER BY ps.TotalScore DESC, u.DisplayName ASC;
