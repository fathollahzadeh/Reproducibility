WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
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
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalViews,
        ps.AverageScore
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    au.DisplayName,
    au.BadgeCount,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount,
    au.TotalViews,
    au.AverageScore,
    RANK() OVER (ORDER BY au.PostCount DESC, au.TotalViews DESC) AS UserRank
FROM ActiveUsers au
WHERE au.BadgeCount > 0
ORDER BY UserRank
LIMIT 10;
