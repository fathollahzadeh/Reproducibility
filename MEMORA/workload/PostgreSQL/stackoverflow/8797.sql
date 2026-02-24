WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.AverageScore,
        ps.TotalViews,
        ps.TotalPosts
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    WHERE u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)
SELECT 
    au.DisplayName,
    COALESCE(au.BadgeCount, 0) AS BadgeCount,
    COALESCE(au.QuestionCount, 0) AS QuestionCount,
    COALESCE(au.AnswerCount, 0) AS AnswerCount,
    COALESCE(au.AverageScore, 0) AS AverageScore,
    COALESCE(au.TotalViews, 0) AS TotalViews,
    COALESCE(au.TotalPosts, 0) AS TotalPosts
FROM ActiveUsers au
ORDER BY au.TotalViews DESC, au.BadgeCount DESC
LIMIT 10;