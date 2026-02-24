WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
UserActivity AS (
    SELECT 
        u.UserId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletedCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 13 THEN 1 ELSE 0 END) AS UndeletedCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN UserReputation u ON u.UserId = p.OwnerUserId
    GROUP BY u.UserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.QuestionCount,
    ur.AnswerCount,
    ur.BadgeCount,
    ua.CloseOpenCount,
    ua.DeletedCount,
    ua.UndeletedCount
FROM UserReputation ur
JOIN UserActivity ua ON ur.UserId = ua.UserId
WHERE ur.Reputation > 1000
ORDER BY ur.Reputation DESC, ur.PostCount DESC;
