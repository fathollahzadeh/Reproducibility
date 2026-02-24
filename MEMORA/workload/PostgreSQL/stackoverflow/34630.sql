
WITH RECURSIVE UserHierarchy AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           0 AS Level
    FROM Users u
    WHERE u.Reputation > 1000  

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           uh.Level + 1
    FROM Users u
    INNER JOIN UserHierarchy uh ON uh.Id = u.Id
    WHERE u.Reputation < uh.Reputation  
),

TagUsage AS (
    SELECT t.TagName, COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),

UserBadges AS (
    SELECT b.UserId, COUNT(b.Id) AS BadgeCount, MIN(b.Date) AS FirstBadgeDate
    FROM Badges b
    GROUP BY b.UserId
),

UserPostStats AS (
    SELECT u.Id AS UserId, u.DisplayName,
           COALESCE(p.AnswerCount, 0) AS AnswerCount,
           COALESCE(p.CommentCount, 0) AS CommentCount
    FROM Users u
    LEFT JOIN (
        SELECT OwnerUserId, SUM(AnswerCount) AS AnswerCount, SUM(CommentCount) AS CommentCount
        FROM Posts 
        GROUP BY OwnerUserId
    ) p ON u.Id = p.OwnerUserId
)

SELECT u.DisplayName, 
       uh.Level, 
       ub.BadgeCount,
       COALESCE(tu.PostCount, 0) AS TagPostCount,
       ups.AnswerCount,
       ups.CommentCount,
       CASE WHEN ub.FirstBadgeDate IS NOT NULL THEN 'Has Badges' ELSE 'No Badges' END AS BadgeStatus
FROM Users u
LEFT JOIN UserHierarchy uh ON u.Id = uh.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN TagUsage tu ON tu.TagName IN (
    SELECT DISTINCT unnest(string_to_array(p.Tags, '><'))
    FROM Posts p
    WHERE p.OwnerUserId = u.Id
) 
LEFT JOIN UserPostStats ups ON u.Id = ups.UserId
WHERE u.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
ORDER BY u.DisplayName;
