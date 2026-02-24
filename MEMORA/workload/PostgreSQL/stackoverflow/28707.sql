WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
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
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostContribution AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
        COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ps.AcceptedAnswerCount, 0) AS TotalAcceptedAnswers,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalAcceptedAnswers,
    TotalBadges,
    BadgeNames
FROM UserPostContribution
ORDER BY TotalPosts DESC
LIMIT 10;