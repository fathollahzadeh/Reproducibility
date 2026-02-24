WITH UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT UserId, Reputation, PostCount, AnswerCount, AcceptedAnswerCount
    FROM UserReputation
    WHERE Reputation > 1000 AND PostCount > 5
),
TopTags AS (
    SELECT t.TagName, COUNT(p.Id) AS TagPostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
    ORDER BY TagPostCount DESC
    LIMIT 10
),
UserTagEngagement AS (
    SELECT au.UserId, tt.TagName, COUNT(p.Id) AS EngagementCount
    FROM ActiveUsers au
    JOIN Posts p ON p.OwnerUserId = au.UserId
    JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN TopTags tt ON tt.TagName = t.TagName
    GROUP BY au.UserId, tt.TagName
)
SELECT au.UserId, au.Reputation, tt.TagName, 
       COALESCE(uge.EngagementCount, 0) AS EngagementCount
FROM ActiveUsers au
CROSS JOIN TopTags tt
LEFT JOIN UserTagEngagement uge ON au.UserId = uge.UserId AND tt.TagName = uge.TagName
ORDER BY au.Reputation DESC, tt.TagPostCount DESC, EngagementCount DESC;
