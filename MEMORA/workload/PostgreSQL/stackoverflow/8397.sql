WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS AnswerScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionScore, 0) AS QuestionScore,
        COALESCE(ps.AnswerScore, 0) AS AnswerScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    u.DisplayName,
    ua.BadgeCount,
    ua.PostCount,
    ua.QuestionScore,
    ua.AnswerScore,
    ua.AvgViewCount,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate
FROM Users u
JOIN UserActivity ua ON u.Id = ua.UserId
WHERE u.Reputation > 1000
ORDER BY ua.QuestionScore DESC, ua.AnswerScore DESC
LIMIT 50;