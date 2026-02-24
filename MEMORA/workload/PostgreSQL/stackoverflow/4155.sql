WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount, 
    SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount, 
    SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),

PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
    SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(ViewCount) AS AvgViews
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR'
    GROUP BY OwnerUserId
),

UserInteraction AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, 
    COALESCE(pb.BadgeCount, 0) AS BadgeCount, 
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.AvgViews, 0) AS AvgViews
    FROM Users u
    LEFT JOIN UserBadges pb ON u.Id = pb.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT ui.UserId, ui.DisplayName, ui.Reputation, 
       ui.BadgeCount, ui.TotalPosts, ui.QuestionCount,
       ui.AnswerCount, ui.AvgViews,
       COALESCE((SELECT STRING_AGG(t.TagName, ', ') 
                 FROM Tags t 
                 JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
                 WHERE p.OwnerUserId = ui.UserId), 'No Tags') AS TagsUsed,
       CASE WHEN ui.BadgeCount > 0 THEN 'Active' ELSE 'Inactive' END AS UserStatus,
       CASE WHEN u.LastAccessDate < cast('2024-10-01' as date) - INTERVAL '6 MONTH' THEN 'Inactive'
            ELSE 'Active' END AS LastActivityStatus
FROM UserInteraction ui
JOIN Users u ON ui.UserId = u.Id
WHERE ui.Reputation > 1000
ORDER BY ui.Reputation DESC
LIMIT 10;