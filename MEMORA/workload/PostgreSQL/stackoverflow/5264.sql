
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 60) AS AvgPostAgeInMinutes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
PostScores AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS NumberOfPosts
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.AvgPostAgeInMinutes,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    ub.HighestBadgeClass,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.NumberOfPosts, 0) AS NumberOfPosts
FROM UserActivity ua
LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN PostScores ps ON ua.UserId = ps.OwnerUserId
WHERE ua.PostCount > 5
ORDER BY COALESCE(ps.TotalScore, 0) DESC, ua.PostCount DESC;
