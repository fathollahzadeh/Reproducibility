WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ba.BadgeCount, 0) AS BadgeCount,
        COALESCE(ma.PostCount, 0) AS TotalPosts,
        COALESCE(ma.Questions, 0) AS TotalQuestions,
        COALESCE(ma.Answers, 0) AS TotalAnswers
    FROM Users u
    LEFT JOIN UserBadges ba ON u.Id = ba.UserId
    LEFT JOIN MostActiveUsers ma ON u.Id = ma.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.BadgeCount,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    CONCAT(ua.DisplayName, ' has earned ', ua.BadgeCount, ' badges and posted a total of ', ua.TotalPosts, 
           ' entries (', ua.TotalQuestions, ' questions and ', ua.TotalAnswers, ' answers).') AS UserSummary
FROM UserActivity ua
ORDER BY ua.Reputation DESC, ua.BadgeCount DESC
LIMIT 10;
