WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Reputation, 
        us.PostCount, 
        us.QuestionCount, 
        us.AnswerCount, 
        us.PopularPostCount, 
        tb.BadgeCount, 
        tb.BadgeNames
    FROM 
        UserStats us
    LEFT JOIN 
        TopBadges tb ON us.UserId = tb.UserId
)
SELECT 
    ua.UserId, 
    ua.DisplayName, 
    ua.Reputation, 
    COALESCE(ua.PostCount, 0) AS TotalPosts, 
    COALESCE(ua.QuestionCount, 0) AS TotalQuestions, 
    COALESCE(ua.AnswerCount, 0) AS TotalAnswers, 
    COALESCE(ua.PopularPostCount, 0) AS PopularPosts, 
    COALESCE(ua.BadgeCount, 0) AS TotalBadges, 
    ua.BadgeNames
FROM 
    UserActivity ua
ORDER BY 
    ua.Reputation DESC, 
    ua.PostCount DESC 
LIMIT 50;
