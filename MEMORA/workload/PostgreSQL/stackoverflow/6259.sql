WITH UserWithBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalScore,
        ps.TotalViews
    FROM Users u
    JOIN UserWithBadges ub ON u.Id = ub.UserId
    JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.BadgeCount,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount,
    au.TotalScore,
    au.TotalViews
FROM ActiveUsers au
ORDER BY au.Reputation DESC, au.BadgeCount DESC, au.TotalScore DESC
LIMIT 10;