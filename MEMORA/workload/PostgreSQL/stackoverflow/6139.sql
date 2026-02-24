WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount, 
        SUM(p.Score) AS TotalScore, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(ps.PostCount, 0) AS PostCount, 
        COALESCE(ps.TotalScore, 0) AS TotalScore, 
        COALESCE(ps.QuestionCount, 0) AS QuestionCount, 
        COALESCE(ps.AnswerCount, 0) AS AnswerCount, 
        COALESCE(ps.TotalViews, 0) AS TotalViews, 
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    DisplayName, 
    PostCount, 
    TotalScore, 
    QuestionCount, 
    AnswerCount, 
    TotalViews, 
    BadgeCount
FROM UserPostBadgeStats
WHERE PostCount > 10 
ORDER BY TotalScore DESC, BadgeCount DESC, PostCount DESC;