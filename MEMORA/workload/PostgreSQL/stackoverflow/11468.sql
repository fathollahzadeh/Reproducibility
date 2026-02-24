WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uc.PostCount, 0) AS PostCount,
        COALESCE(uc.QuestionCount, 0) AS QuestionCount,
        COALESCE(uc.AnswerCount, 0) AS AnswerCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN UserPostCounts uc ON u.Id = uc.UserId
    LEFT JOIN BadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    BadgeCount
FROM UserStats
ORDER BY Reputation DESC, PostCount DESC
LIMIT 100;